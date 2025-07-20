<#
.SYNOPSIS
    RocketChat Support Dump Analyzer - Main automation script for analyzing RocketChat logs and support dumps.

.DESCRIPTION
    This script provides comprehensive analysis of RocketChat support dumps including:
    - System logs analysis with error detection
    - Server statistics review
    - Configuration settings validation
    - Performance metrics evaluation
    - Security event identification
    - Omnichannel settings review
    - Apps/integrations audit

.PARAMETER DumpPath
    Path to the RocketChat support dump directory or specific dump files

.PARAMETER OutputFormat
    Output format for the analysis report (Console, JSON, CSV, HTML)

.PARAMETER Severity
    Minimum severity level to report (Info, Warning, Error, Critical)

.PARAMETER ExportPath
    Path where to export the analysis report

.PARAMETER ConfigFile
    Path to custom configuration file for analysis rules

.EXAMPLE
    .\Analyze-RocketChatDump.ps1 -DumpPath "C:\Support\7.8.0-support-dump" -OutputFormat HTML -ExportPath "C:\Reports\analysis.html"

.EXAMPLE
    .\Analyze-RocketChatDump.ps1 -DumpPath "C:\Support\7.8.0-support-dump" -Severity Error

.NOTES
    Author: Support Engineering Team
    Version: 1.3.0
    Requires: PowerShell 5.1 or later
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Path to RocketChat support dump directory or files")]
    [ValidateScript({
        if (-not (Test-Path $_ -PathType Any)) {
            throw "Path does not exist: $_"
        }
        if (-not (Test-Path $_ -PathType Container)) {
            # If it's a file, check if it's a supported type
            $extension = [System.IO.Path]::GetExtension($_).ToLower()
            if ($extension -notin @('.json', '.tar', '.zip', '.gz')) {
                Write-Warning "File type '$extension' may not be supported. Supported types: .json, .tar, .zip, .gz"
            }
        }
        $true
    })]
    [string]$DumpPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "JSON", "CSV", "HTML")]
    [string]$OutputFormat = "Console",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Info", "Warning", "Error", "Critical")]
    [string]$Severity = "Info",
    
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if ($_ -and -not (Test-Path (Split-Path $_) -PathType Container)) {
            throw "Export directory does not exist: $(Split-Path $_)"
        }
        $true
    })]
    [string]$ExportPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if ($_ -and -not (Test-Path $_ -PathType Leaf)) {
            Write-Warning "Config file does not exist: $_. Using default configuration."
        }
        $true
    })]
    [string]$ConfigFile = ".\config\analysis-rules.json"
)

# Enhanced error handling and strict mode
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version Latest

# Global error handling
trap {
    Write-Error "Critical error occurred: $($_.Exception.Message)"
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host "  Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "  Command: $($_.InvocationInfo.Line.Trim())" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host "  Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    }
    exit 1
}

# Prerequisite checks
function Test-Prerequisites {
    Write-Verbose "Checking PowerShell version and prerequisites..."
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.1 or later is required. Current version: $($PSVersionTable.PSVersion)"
    }
    
    # Check if running with sufficient privileges for file access
    try {
        $testPath = Join-Path $env:TEMP "rocketchat_test_$(Get-Random)"
        New-Item -Path $testPath -ItemType File -Force | Out-Null
        Remove-Item -Path $testPath -Force
    }
    catch {
        Write-Warning "Limited file system access detected. Some operations may fail."
    }
    
    # Validate dump path accessibility
    if (-not (Test-Path $DumpPath -PathType Any)) {
        throw "Dump path does not exist or is not accessible: $DumpPath"
    }
    
    # Check for required JSON handling capability
    try {
        $null = ConvertTo-Json @{test = "value"} -ErrorAction Stop
        $null = ConvertFrom-Json '{"test": "value"}' -ErrorAction Stop
    }
    catch {
        throw "JSON processing capabilities are not available in this PowerShell session"
    }
    
    Write-Verbose "Prerequisites check completed successfully"
}

# Import required modules with error handling
function Import-RequiredModules {
    $ModulePath = Join-Path $PSScriptRoot "modules"
    
    if (-not (Test-Path $ModulePath -PathType Container)) {
        Write-Warning "Modules directory not found: $ModulePath"
        Write-Host "Running in fallback mode without enhanced modules..." -ForegroundColor Yellow
        return $false
    }
    
    $RequiredModules = @(
        "RocketChatLogParser.psm1",
        "RocketChatAnalyzer.psm1", 
        "ReportGenerator.psm1"
    )
    
    $ImportSuccess = $true
    foreach ($Module in $RequiredModules) {
        $ModuleFile = Join-Path $ModulePath $Module
        
        if (Test-Path $ModuleFile -PathType Leaf) {
            try {
                Import-Module $ModuleFile -Force -ErrorAction Stop
                Write-Verbose "Successfully imported module: $Module"
            }
            catch {
                Write-Warning "Failed to import module '$Module': $($_.Exception.Message)"
                $ImportSuccess = $false
            }
        }
        else {
            Write-Warning "Module file not found: $ModuleFile"
            $ImportSuccess = $false
        }
    }
    
    if (-not $ImportSuccess) {
        Write-Host "Some modules failed to load. Continuing with built-in functionality..." -ForegroundColor Yellow
    }
    
    return $ImportSuccess
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

try {
    # Initialize analysis with prerequisites check
    Write-Verbose "Initializing RocketChat Support Dump Analyzer..."
    Test-Prerequisites
    
    # Import modules with fallback capability
    $ModulesLoaded = Import-RequiredModules
    if (-not $ModulesLoaded) {
        Write-Warning "Running with limited functionality due to module loading issues"
    }

# Initialize analysis results
$AnalysisResults = @{
    Timestamp = Get-Date
    DumpPath = $DumpPath
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    ModulesLoaded = $ModulesLoaded
    Summary = @{
        TotalIssues = 0
        CriticalIssues = 0
        ErrorIssues = 0
        WarningIssues = 0
        InfoIssues = 0
    }
    SystemInfo = @{}
    LogAnalysis = @{}
    SettingsAnalysis = @{}
    StatisticsAnalysis = @{}
    OmnichannelAnalysis = @{}
    AppsAnalysis = @{}
    Recommendations = @()
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Cyan
}

function Write-Status {
    param(
        [string]$Message,
        [string]$Status = "Info"
    )
    
    $color = switch ($Status) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Critical" { "Magenta" }
        "Success" { "Green" }
        default { "White" }
    }
    
    $prefix = switch ($Status) {
        "Info" { "[INFO]" }
        "Warning" { "[WARN]" }
        "Error" { "[ERROR]" }
        "Critical" { "[CRITICAL]" }
        "Success" { "[SUCCESS]" }
        default { "[INFO]" }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Get-DumpFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    $files = @{}
    $FilesFound = 0
    
    try {
        if (Test-Path $Path -PathType Container) {
            Write-Verbose "Scanning directory for dump files: $Path"
            
            # Enhanced file discovery with error handling
            $FilePatterns = @{
                'Log' = @('*log*.json')
                'Settings' = @('*settings*.json', '*config*.json')
                'Statistics' = @('*statistics*.json', '*stats*.json')
                'Omnichannel' = @('*omnichannel*.json', '*omni*.json')
                'Apps' = @('*apps*.json', '*app*.json')
            }
            
            foreach ($FileType in $FilePatterns.Keys) {
                foreach ($Pattern in $FilePatterns[$FileType]) {
                    try {
                        $FoundFiles = Get-ChildItem -Path $Path -Filter $Pattern -ErrorAction SilentlyContinue
                        if ($FoundFiles) {
                            $SelectedFile = $FoundFiles | Select-Object -First 1
                            
                            # Validate file accessibility and content
                            if (Test-FileAccessibility $SelectedFile.FullName) {
                                $files[$FileType] = $SelectedFile
                                $FilesFound++
                                Write-Verbose "Found $FileType file: $($SelectedFile.Name) ($(Format-FileSize $SelectedFile.Length))"
                                break  # Move to next file type once found
                            }
                        }
                    }
                    catch {
                        Write-Warning "Error searching for $FileType files with pattern '$Pattern': $($_.Exception.Message)"
                    }
                }
            }
        } 
        elseif (Test-Path $Path -PathType Leaf) {
            Write-Verbose "Processing single file: $Path"
            
            # Validate single file
            if (-not (Test-FileAccessibility $Path)) {
                throw "File is not accessible or readable: $Path"
            }
            
            # Determine file type by name and optionally by content
            $fileName = Split-Path $Path -Leaf
            $fileItem = Get-Item $Path
            
            switch -Regex ($fileName.ToLower()) {
                'log' { 
                    $files.Log = $fileItem
                    $FilesFound++
                }
                'settings|config' { 
                    $files.Settings = $fileItem
                    $FilesFound++
                }
                'statistics|stats' { 
                    $files.Statistics = $fileItem
                    $FilesFound++
                }
                'omnichannel|omni' { 
                    $files.Omnichannel = $fileItem
                    $FilesFound++
                }
                'apps|app' { 
                    $files.Apps = $fileItem
                    $FilesFound++
                }
                default {
                    Write-Warning "Unable to determine file type from name: $fileName"
                    # Try to determine by content structure if it's JSON
                    if ($fileName -match '\.json$') {
                        $ContentType = Get-JsonContentType $Path
                        if ($ContentType) {
                            $files[$ContentType] = $fileItem
                            $FilesFound++
                            Write-Verbose "Determined file type by content: $ContentType"
                        }
                        else {
                            $files.Unknown = $fileItem
                            $FilesFound++
                        }
                    }
                }
            }
        }
        else {
            throw "Path is neither a file nor directory: $Path"
        }
        
        if ($FilesFound -eq 0) {
            Write-Warning "No supported dump files found in: $Path"
            Write-Host "Supported file patterns:" -ForegroundColor Yellow
            Write-Host "  Logs: *log*.json" -ForegroundColor Gray
            Write-Host "  Settings: *settings*.json, *config*.json" -ForegroundColor Gray
            Write-Host "  Statistics: *statistics*.json, *stats*.json" -ForegroundColor Gray
            Write-Host "  Omnichannel: *omnichannel*.json, *omni*.json" -ForegroundColor Gray
            Write-Host "  Apps: *apps*.json, *app*.json" -ForegroundColor Gray
        }
        else {
            Write-Verbose "Found $FilesFound dump file(s) for analysis"
        }
    }
    catch {
        Write-Error "Error discovering dump files: $($_.Exception.Message)"
        throw
    }
    
    return $files
}

# Helper function to test file accessibility
function Test-FileAccessibility {
    param([string]$FilePath)
    
    try {
        # Test if file exists and is readable
        if (-not (Test-Path $FilePath -PathType Leaf)) {
            return $false
        }
        
        # Test read access
        $null = Get-Content $FilePath -TotalCount 1 -ErrorAction Stop
        
        # For JSON files, test basic JSON validity
        if ($FilePath -match '\.json$') {
            try {
                $testContent = Get-Content $FilePath -Raw -ErrorAction Stop
                if ($testContent) {
                    $null = ConvertFrom-Json $testContent -ErrorAction Stop
                }
            }
            catch {
                Write-Warning "JSON file may be corrupted or incomplete: $FilePath"
                return $false
            }
        }
        
        return $true
    }
    catch {
        Write-Warning "File accessibility test failed for: $FilePath - $($_.Exception.Message)"
        return $false
    }
}

# Helper function to get JSON content type
function Get-JsonContentType {
    param([string]$FilePath)
    
    try {
        $content = Get-Content $FilePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        
        # Check for specific content patterns
        if ($content.logs -or $content.queue) { return 'Log' }
        if ($content.settings -or ($content.PSObject.Properties.Name -match 'API_' -or $content.PSObject.Properties.Name -match '_')-contains $true) { return 'Settings' }
        if ($content.totalUsers -or $content.totalMessages) { return 'Statistics' }
        if ($content.omnichannel -or $content.livechat) { return 'Omnichannel' }
        if ($content.apps -or $content.marketplace) { return 'Apps' }
        
        return $null
    }
    catch {
        return $null
    }
}

# Helper function to format file sizes
function Format-FileSize {
    param([long]$Size)
    
    if ($Size -gt 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    elseif ($Size -gt 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    elseif ($Size -gt 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
    else { return "$Size bytes" }
}

try {
    Write-Header "RocketChat Support Dump Analyzer"
    Write-Status "Starting analysis of: $DumpPath" "Info"
    
    # Load configuration
    if (Test-Path $ConfigFile) {
        Write-Status "Loading configuration from: $ConfigFile" "Info"
        $config = Get-Content $ConfigFile | ConvertFrom-Json
    } else {
        Write-Status "Using default configuration" "Warning"
        $config = @{
            LogPatterns = @{
                Error = @("error", "exception", "failed", "timeout")
                Warning = @("warn", "deprecated", "slow")
                Security = @("auth", "login", "permission", "unauthorized")
            }
            PerformanceThresholds = @{
                ResponseTime = 5000
                MemoryUsage = 80
                CPUUsage = 90
            }
        }
    }
    
    # Get dump files
    $dumpFiles = Get-DumpFiles -Path $DumpPath
    
    # Analyze each component
    if ($dumpFiles.Log) {
        Write-Header "Analyzing System Logs"
        Write-Status "Processing: $($dumpFiles.Log.Name)" "Info"
        $AnalysisResults.LogAnalysis = Invoke-LogAnalysis -LogFile $dumpFiles.Log.FullName -Config $config
    }
    
    if ($dumpFiles.Settings) {
        Write-Header "Analyzing Settings"
        Write-Status "Processing: $($dumpFiles.Settings.Name)" "Info"
        $AnalysisResults.SettingsAnalysis = Invoke-SettingsAnalysis -SettingsFile $dumpFiles.Settings.FullName -Config $config
    }
    
    if ($dumpFiles.Statistics) {
        Write-Header "Analyzing Server Statistics"
        Write-Status "Processing: $($dumpFiles.Statistics.Name)" "Info"
        $AnalysisResults.StatisticsAnalysis = Invoke-StatisticsAnalysis -StatisticsFile $dumpFiles.Statistics.FullName -Config $config
    }
    
    if ($dumpFiles.Omnichannel) {
        Write-Header "Analyzing Omnichannel Configuration"
        Write-Status "Processing: $($dumpFiles.Omnichannel.Name)" "Info"
        $AnalysisResults.OmnichannelAnalysis = Invoke-OmnichannelAnalysis -OmnichannelFile $dumpFiles.Omnichannel.FullName -Config $config
    }
    
    if ($dumpFiles.Apps) {
        Write-Header "Analyzing Installed Apps"
        Write-Status "Processing: $($dumpFiles.Apps.Name)" "Info"
        $AnalysisResults.AppsAnalysis = Invoke-AppsAnalysis -AppsFile $dumpFiles.Apps.FullName -Config $config
    }
    
    # Generate summary
    Write-Header "Analysis Summary"
    $totalIssues = 0
    foreach ($analysis in $AnalysisResults.Values) {
        if ($analysis -is [hashtable] -and $analysis.ContainsKey("Issues")) {
            $totalIssues += $analysis.Issues.Count
        }
    }
    
    $AnalysisResults.Summary.TotalIssues = $totalIssues
    Write-Status "Total issues found: $totalIssues" $(if ($totalIssues -gt 0) { "Warning" } else { "Success" })
    
    # Generate report
    switch ($OutputFormat) {
        "Console" {
            Write-ConsoleReport -Results $AnalysisResults -MinSeverity $Severity
        }
        "JSON" {
            $report = New-JSONReport -Results $AnalysisResults
            if ($ExportPath) {
                $report | Out-File -FilePath $ExportPath -Encoding UTF8
                Write-Status "JSON report exported to: $ExportPath" "Success"
            } else {
                Write-Output $report
            }
        }
        "CSV" {
            $report = New-CSVReport -Results $AnalysisResults
            if ($ExportPath) {
                $report | Export-Csv -Path $ExportPath -NoTypeInformation
                Write-Status "CSV report exported to: $ExportPath" "Success"
            } else {
                Write-Output $report
            }
        }
        "HTML" {
            $report = New-HTMLReport -Results $AnalysisResults
            if ($ExportPath) {
                $report | Out-File -FilePath $ExportPath -Encoding UTF8
                Write-Status "HTML report exported to: $ExportPath" "Success"
            } else {
                Write-Output $report
            }
        }
    }
    
    Write-Header "Analysis Complete"
    Write-Status "RocketChat dump analysis completed successfully" "Success"
    
} catch {
    Write-Status "Critical error during analysis: $($_.Exception.Message)" "Critical"
    Write-Host "Error Details:" -ForegroundColor Red
    Write-Host "  Script: $($_.InvocationInfo.ScriptName)" -ForegroundColor Red
    Write-Host "  Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "  Command: $($_.InvocationInfo.Line.Trim())" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host "  Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    }
    exit 1
} finally {
    # Cleanup any temporary resources
    Write-Verbose "Cleaning up resources..."
    # Add any cleanup code here if needed
}
