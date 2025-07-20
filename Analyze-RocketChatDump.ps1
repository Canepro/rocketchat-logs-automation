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
    Version: 1.0.0
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

# Import required modules
$ModulePath = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $ModulePath "RocketChatLogParser.psm1") -Force
Import-Module (Join-Path $ModulePath "RocketChatAnalyzer.psm1") -Force
Import-Module (Join-Path $ModulePath "ReportGenerator.psm1") -Force

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
    param([string]$Path)
    
    $files = @{}
    
    if (Test-Path $Path -PathType Container) {
        # Directory - look for standard dump files
        $files.Log = Get-ChildItem -Path $Path -Filter "*log*.json" | Select-Object -First 1
        $files.Settings = Get-ChildItem -Path $Path -Filter "*settings*.json" | Select-Object -First 1
        $files.Statistics = Get-ChildItem -Path $Path -Filter "*statistics*.json" | Select-Object -First 1
        $files.Omnichannel = Get-ChildItem -Path $Path -Filter "*omnichannel*.json" | Select-Object -First 1
        $files.Apps = Get-ChildItem -Path $Path -Filter "*apps*.json" | Select-Object -First 1
    } else {
        # Single file - determine type by name
        $fileName = Split-Path $Path -Leaf
        if ($fileName -match "log") { $files.Log = Get-Item $Path }
        elseif ($fileName -match "settings") { $files.Settings = Get-Item $Path }
        elseif ($fileName -match "statistics") { $files.Statistics = Get-Item $Path }
        elseif ($fileName -match "omnichannel") { $files.Omnichannel = Get-Item $Path }
        elseif ($fileName -match "apps") { $files.Apps = Get-Item $Path }
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
    Write-Status "Error during analysis: $($_.Exception.Message)" "Critical"
    Write-Status "Stack trace: $($_.ScriptStackTrace)" "Error"
    exit 1
}
