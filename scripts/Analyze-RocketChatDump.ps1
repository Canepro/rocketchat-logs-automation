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
    Version: 1.4.8
    Requires: PowerShell 5.1 or later
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Path to RocketChat support dump directory or files")]
    [ValidateScript({Test-Path $_ -PathType Any})]
    [string]$DumpPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "JSON", "CSV", "HTML")]
    [string]$OutputFormat = "Console",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Info", "Warning", "Error", "Critical")]
    [string]$Severity = "Info",
    
    [Parameter(Mandatory = $false)]
    [string]$ExportPath,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = ".\config\analysis-rules.json"
)

Write-Host "*** SCRIPT DEBUG: Parameters parsed - OutputFormat is '$OutputFormat' ***" -ForegroundColor Red

# Import required modules
$ModulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "modules"
Write-Host "*** DEBUG: Starting script execution ***" -ForegroundColor Magenta
Import-Module (Join-Path $ModulePath "RocketChatLogParser.psm1") -Force
Import-Module (Join-Path $ModulePath "RocketChatAnalyzer.psm1") -Force
Import-Module (Join-Path $ModulePath "ReportGenerator.psm1") -Force
Write-Host "*** DEBUG: Modules imported successfully ***" -ForegroundColor Magenta

# Initialize analysis results
$AnalysisResults = @{
    Timestamp = Get-Date
    DumpPath = $DumpPath
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
    <#
    .SYNOPSIS
        Discovers and validates RocketChat support dump files by pattern matching.
    
    .DESCRIPTION
        This function intelligently discovers RocketChat dump files by analyzing
        file names and directory structure. It supports both directory analysis
        and single file processing.
    
    .PARAMETER Path
        Path to RocketChat support dump directory or specific dump file.
        Supports both relative and absolute paths.
    
    .EXAMPLE
        $files = Get-DumpFiles -Path "C:\Support\7.8.0-support-dump"
        if ($files.Log) { Write-Host "Found log file: $($files.Log.Name)" }
    
    .OUTPUTS
        Hashtable containing discovered files:
        - Log: System log files (*log*.json)
        - Settings: Configuration settings (*settings*.json)
        - Statistics: Server statistics (*statistics*.json)
        - Omnichannel: Livechat configuration (*omnichannel*.json)
        - Apps: Installed apps information (*apps*.json)
    
    .NOTES
        File discovery is based on filename patterns and is case-insensitive.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    $files = @{}
    
    if (Test-Path $Path -PathType Container) {
        # Directory - look for standard dump files
        $files.Log = Get-ChildItem -Path $Path -Filter "*log*.json" | Select-Object -First 1
        
        # Prioritize main settings file over omnichannel settings
        $files.Settings = Get-ChildItem -Path $Path -Filter "*settings*.json" | 
                         Where-Object { $_.Name -notlike "*omnichannel*" } | 
                         Select-Object -First 1
        if (-not $files.Settings) {
            $files.Settings = Get-ChildItem -Path $Path -Filter "*settings*.json" | Select-Object -First 1
        }
        
        $files.Statistics = Get-ChildItem -Path $Path -Filter "*statistics*.json" | Select-Object -First 1
        $files.Omnichannel = Get-ChildItem -Path $Path -Filter "*omnichannel*.json" | Select-Object -First 1
        $files.Apps = Get-ChildItem -Path $Path -Filter "*apps*.json" | Select-Object -First 1
    } else {
        # Single file - determine type by name or inspect content
        $fileName = Split-Path $Path -Leaf
        $fileItem = Get-Item $Path
        
        if ($fileName -match "log") { 
            $files.Log = $fileItem 
        }
        elseif ($fileName -match "settings") { 
            $files.Settings = $fileItem 
        }
        elseif ($fileName -match "statistics") { 
            $files.Statistics = $fileItem 
        }
        elseif ($fileName -match "omnichannel") { 
            $files.Omnichannel = $fileItem 
        }
        elseif ($fileName -match "apps") { 
            $files.Apps = $fileItem 
        }
        else {
            # Check if it's a comprehensive JSON file with multiple sections
            try {
                $content = Get-Content $Path | ConvertFrom-Json
                if ($content.settings -or $content.users -or $content.channels) {
                    # This appears to be a comprehensive dump file
                    Write-Status "Detected comprehensive dump file containing multiple sections" "Info"
                    $files.Settings = $fileItem  # Treat as settings file for analysis
                    $files.Statistics = $fileItem  # Also use for statistics
                    $files.Log = $fileItem  # Also use for log analysis if messages present
                }
            }
            catch {
                Write-Status "Unable to determine file type for: $fileName" "Warning"
            }
        }
    }
    
    return $files
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
    
    # Clear the pipeline to prevent contamination
    $null = $null
    [System.GC]::Collect()
    
    # Generate report
    Write-Host "DEBUG: OutputFormat = '$OutputFormat'" -ForegroundColor Magenta
    Write-Host "DEBUG: OutputFormat type = '$($OutputFormat.GetType().FullName)'" -ForegroundColor Magenta
    
    # Clear any pipeline objects before switch
    $null = $null
    
    switch ($OutputFormat.Trim()) {
        "Console" {
            Write-Host "DEBUG: Matched Console case" -ForegroundColor Green
            Write-ConsoleReport -Results $AnalysisResults -MinSeverity $Severity
        }
        "JSON" {
            Write-Host "DEBUG: Matched JSON case" -ForegroundColor Green
            $report = New-JSONReport -Results $AnalysisResults
            if ($ExportPath) {
                $report | Out-File -FilePath $ExportPath -Encoding UTF8
                Write-Status "JSON report exported to: $ExportPath" "Success"
            } else {
                Write-Output $report
            }
        }
        "CSV" {
            Write-Host "DEBUG: Matched CSV case" -ForegroundColor Green
            $report = New-CSVReport -Results $AnalysisResults
            if ($ExportPath) {
                $report | Export-Csv -Path $ExportPath -NoTypeInformation
                Write-Status "CSV report exported to: $ExportPath" "Success"
            } else {
                Write-Output $report
            }
        }
        "HTML" {
            Write-Host "DEBUG: Matched HTML case" -ForegroundColor Green
            $report = New-HTMLReport -Results $AnalysisResults
            if ($ExportPath) {
                $htmlFile = $ExportPath
            } else {
                # Auto-generate filename with timestamp
                $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
                $htmlFile = "RocketChat-Analysis-Report_$timestamp.html"
            }
            
            # Save the HTML report
            $report | Out-File -FilePath $htmlFile -Encoding UTF8
            $fullPath = (Resolve-Path $htmlFile).Path
            Write-Status "HTML report saved to: $fullPath" "Success"
            
            # Attempt to open in default browser with multiple fallback methods
            try {
                $opened = $false
                Write-Status "Attempting to open report in default browser..." "Info"
                
                # Method 1: Try Start-Process (most common)
                try {
                    Start-Process $fullPath -ErrorAction Stop
                    $opened = $true
                    Write-Verbose "Successfully opened with Start-Process"
                } catch {
                    Write-Verbose "Start-Process failed: $($_.Exception.Message)"
                }
                
                # Method 2: Try Invoke-Item if Start-Process fails
                if (-not $opened) {
                    try {
                        Invoke-Item $fullPath -ErrorAction Stop
                        $opened = $true
                        Write-Verbose "Successfully opened with Invoke-Item"
                    } catch {
                        Write-Verbose "Invoke-Item failed: $($_.Exception.Message)"
                    }
                }
                
                # Method 3: Try cmd.exe start as fallback
                if (-not $opened) {
                    try {
                        $startCmd = "cmd.exe /c start `"`" `"$fullPath`""
                        Invoke-Expression $startCmd -ErrorAction Stop
                        $opened = $true
                        Write-Verbose "Successfully opened with cmd.exe start"
                    } catch {
                        Write-Verbose "cmd.exe start failed: $($_.Exception.Message)"
                    }
                }
                
                # Method 4: Try explorer.exe as last resort
                if (-not $opened) {
                    try {
                        Start-Process "explorer.exe" -ArgumentList $fullPath -ErrorAction Stop
                        $opened = $true
                        Write-Verbose "Successfully opened with explorer.exe"
                    } catch {
                        Write-Verbose "explorer.exe failed: $($_.Exception.Message)"
                    }
                }
                
                if ($opened) {
                    Write-Status "Report opened in default browser" "Success"
                } else {
                    Write-Status "Unable to auto-open browser. Please open manually: $fullPath" "Info"
                }
            } catch {
                Write-Status "Report saved successfully. Please open manually: $fullPath" "Info"
            }
        }
        default {
            Write-Host "DEBUG: Matched DEFAULT case for '$OutputFormat'" -ForegroundColor Red
            Write-ConsoleReport -Results $AnalysisResults -MinSeverity $Severity
        }
    }
    
    Write-Header "Analysis Complete"
    Write-Status "RocketChat dump analysis completed successfully" "Success"
    
} catch {
    Write-Status "Error during analysis: $($_.Exception.Message)" "Critical"
    Write-Status "Stack trace: $($_.ScriptStackTrace)" "Error"
    exit 1
}
