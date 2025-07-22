<#
.SYNOPSIS
    Report Generator Module - Functions for generating various report formats.
.DESCRIPTION

    This module provides functions to generate reports in different formats including
    console output, JSON, CSV, and HTML reports.
#>

# Import required modules
try {
    $ModulePath = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $AnalyzerModulePath = Join-Path $ModulePath "RocketChatAnalyzer.psm1"
    if (Test-Path $AnalyzerModulePath) {
        Import-Module $AnalyzerModulePath -Force -Global
    }
} catch {
    Write-Warning "Could not import RocketChatAnalyzer module: $($_.Exception.Message)"
    Throw "Critical error: Failed to import RocketChatAnalyzer module. The script cannot continue."
}

function Write-ConsoleReport {
    <#
    .SYNOPSIS
        Displays analysis results in a formatted console output.
    
    .PARAMETER Results
        Analysis results from the main script
    
    .PARAMETER MinSeverity
        Minimum severity level to display
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Results,
        
        [Parameter(Mandatory = $false)]
        [string]$MinSeverity = "Info"
    )
    
    # Define severity levels for filtering
    $severityLevels = @{
        "Info" = 1
        "Warning" = 2
        "Error" = 3
        "Critical" = 4
    }
    
    $minLevel = $severityLevels[$MinSeverity]
    
    # Calculate health score
    $healthScore = Get-HealthScore -AnalysisResults $Results
    
    Write-Host "`n" -NoNewline
    Write-Host "🚀 ROCKETCHAT SUPPORT DUMP ANALYSIS REPORT" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    # Overall Health Score
    Write-Host "`n📊 HEALTH OVERVIEW" -ForegroundColor Green
    Write-Host "-" * 20 -ForegroundColor Gray
    
    $scoreColor = if ($healthScore.OverallScore -ge 90) { "Green" } 
                 elseif ($healthScore.OverallScore -ge 70) { "Yellow" } 
                 else { "Red" }
    
    Write-Host "Overall Health Score: " -NoNewline
    Write-Host "$($healthScore.OverallScore)%" -ForegroundColor $scoreColor
    
    Write-Host "Issues Summary:" -ForegroundColor White
    Write-Host "  • Critical: $($healthScore.Issues.Critical)" -ForegroundColor Magenta
    Write-Host "  • Error:    $($healthScore.Issues.Error)" -ForegroundColor Red
    Write-Host "  • Warning:  $($healthScore.Issues.Warning)" -ForegroundColor Yellow
    Write-Host "  • Info:     $($healthScore.Issues.Info)" -ForegroundColor Cyan
    
    # Component Scores
    Write-Host "`nComponent Health:" -ForegroundColor White
    foreach ($component in $healthScore.ComponentScores.GetEnumerator()) {
        $color = if ($component.Value -ge 90) { "Green" } 
                elseif ($component.Value -ge 70) { "Yellow" } 
                else { "Red" }
        Write-Host "  • $($component.Key): $($component.Value)%" -ForegroundColor $color
    }
    
    # Log Analysis
    if ($Results.LogAnalysis -and $Results.LogAnalysis.Issues) {
        Write-Host "`n📝 LOG ANALYSIS" -ForegroundColor Green
        Write-Host "-" * 20 -ForegroundColor Gray
        
        $logSummary = $Results.LogAnalysis.Summary
        Write-Host "Total Log Entries: $($logSummary.TotalEntries)" -ForegroundColor White
        Write-Host "Errors: $($logSummary.ErrorCount) | Warnings: $($logSummary.WarningCount) | Info: $($logSummary.InfoCount)" -ForegroundColor Gray
        
        if ($Results.LogAnalysis.TimeRange.Start) {
            Write-Host "Time Range: $($Results.LogAnalysis.TimeRange.Start) to $($Results.LogAnalysis.TimeRange.End)" -ForegroundColor Gray
        }
        
        # Display issues
        $filteredIssues = if ($Results.LogAnalysis -and $Results.LogAnalysis.Issues) {
            $Results.LogAnalysis.Issues | Where-Object { $severityLevels[$_.Severity] -ge $minLevel }
        } else { @() }
        if ($filteredIssues.Count -gt 0) {
            Write-Host "`nTop Issues:" -ForegroundColor Yellow
            $filteredIssues | Select-Object -First 10 | ForEach-Object {
                $color = switch ($_.Severity) {
                    "Critical" { "Magenta" }
                    "Error" { "Red" }
                    "Warning" { "Yellow" }
                    default { "Cyan" }
                }
                Write-Host "  [$($_.Severity)] $($_.Message)" -ForegroundColor $color
            }
        }
        
        # Error patterns
        if ($Results.LogAnalysis.Patterns -and $Results.LogAnalysis.Patterns.Count -gt 0) {
            Write-Host "`nError Patterns:" -ForegroundColor Yellow
            $Results.LogAnalysis.Patterns.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 | ForEach-Object {
                Write-Host "  • $($_.Key): $($_.Value) occurrences" -ForegroundColor Red
            }
        }
    }
    
    # Settings Analysis
    if ($Results.SettingsAnalysis -and $Results.SettingsAnalysis.Issues) {
        Write-Host "`n⚙️ SETTINGS ANALYSIS" -ForegroundColor Green
        Write-Host "-" * 20 -ForegroundColor Gray
        
        $filteredSettingsIssues = if ($Results.SettingsAnalysis -and $Results.SettingsAnalysis.Issues) {
            $Results.SettingsAnalysis.Issues | Where-Object { $severityLevels[$_.Severity] -ge $minLevel }
        } else { @() }
        if ($filteredSettingsIssues.Count -gt 0) {
            Write-Host "Configuration Issues:" -ForegroundColor Yellow
            $filteredSettingsIssues | ForEach-Object {
                $color = switch ($_.Severity) {
                    "Critical" { "Magenta" }
                    "Error" { "Red" }
                    "Warning" { "Yellow" }
                    default { "Cyan" }
                }
                Write-Host "  [$($_.Severity)] $($_.Message)" -ForegroundColor $color
            }
        }
        
        Write-Host "`nSecurity Settings: $($Results.SettingsAnalysis.SecuritySettings.Count) reviewed" -ForegroundColor Gray
        Write-Host "Performance Settings: $($Results.SettingsAnalysis.PerformanceSettings.Count) reviewed" -ForegroundColor Gray
    }
    
    # Statistics Analysis
    if ($Results.StatisticsAnalysis) {
        Write-Host "`n📈 SERVER STATISTICS" -ForegroundColor Green
        Write-Host "-" * 20 -ForegroundColor Gray
        
        if ($Results.StatisticsAnalysis.ServerInfo) {
            $serverInfo = $Results.StatisticsAnalysis.ServerInfo
            Write-Host "RocketChat Version: $($serverInfo.Version)" -ForegroundColor White
            if ($serverInfo.InstalledAt) {
                Write-Host "Installed: $($serverInfo.InstalledAt)" -ForegroundColor Gray
            }
        }
        
        if ($Results.StatisticsAnalysis.PerformanceMetrics) {
            $perf = $Results.StatisticsAnalysis.PerformanceMetrics
            
            if ($perf.Memory) {
                $memMB = [math]::Round($perf.Memory.Used / 1024 / 1024, 2)
                Write-Host "Memory Usage: ${memMB}MB" -ForegroundColor $(if ($memMB -gt 2048) { "Red" } elseif ($memMB -gt 1024) { "Yellow" } else { "Green" })
            }
            
            if ($perf.Users) {
                Write-Host "Users: $($perf.Users.Total) total, $($perf.Users.Online) online" -ForegroundColor White
            }
            
            if ($perf.Messages) {
                Write-Host "Messages: $($perf.Messages.Total) total" -ForegroundColor White
            }
        }
        
        $filteredStatsIssues = if ($Results.StatisticsAnalysis -and $Results.StatisticsAnalysis.Issues) {
            $Results.StatisticsAnalysis.Issues | Where-Object { $severityLevels[$_.Severity] -ge $minLevel }
        } else { @() }
        if ($filteredStatsIssues.Count -gt 0) {
            Write-Host "`nPerformance Issues:" -ForegroundColor Yellow
            $filteredStatsIssues | ForEach-Object {
                $color = switch ($_.Severity) {
                    "Critical" { "Magenta" }
                    "Error" { "Red" }
                    "Warning" { "Yellow" }
                    default { "Cyan" }
                }
                Write-Host "  [$($_.Severity)] $($_.Message)" -ForegroundColor $color
            }
        }
    }
    
    # Security Analysis
    $allIssues = @()
    foreach ($analysis in $Results.Values) {
        if ($analysis -is [hashtable] -and $analysis.ContainsKey("Issues")) {
            $allIssues += $analysis.Issues
        }
    }
    
    if ($Results.SettingsAnalysis) {
        $securityAnalysis = Get-SecurityAnalysis -Settings $Results.SettingsAnalysis -Issues $allIssues
        
        Write-Host "`n🔒 SECURITY ANALYSIS" -ForegroundColor Green
        Write-Host "-" * 20 -ForegroundColor Gray
        
        $scoreColor = if ($securityAnalysis.SecurityScore -ge 90) { "Green" } 
                     elseif ($securityAnalysis.SecurityScore -ge 70) { "Yellow" } 
                     else { "Red" }
        Write-Host "Security Score: $($securityAnalysis.SecurityScore)%" -ForegroundColor $scoreColor
        
        if ($securityAnalysis.SecurityIssues.Count -gt 0) {
            Write-Host "`nSecurity Issues:" -ForegroundColor Yellow
            $securityAnalysis.SecurityIssues | Select-Object -First 5 | ForEach-Object {
                Write-Host "  • $_" -ForegroundColor Red
            }
        }
        
        if ($securityAnalysis.Recommendations.Count -gt 0) {
            Write-Host "`nSecurity Recommendations:" -ForegroundColor Yellow
            $securityAnalysis.Recommendations | Select-Object -First 3 | ForEach-Object {
                Write-Host "  • $_" -ForegroundColor Cyan
            }
        }
    }
    
    # Recommendations
    Write-Host "`n💡 RECOMMENDATIONS" -ForegroundColor Green
    Write-Host "-" * 20 -ForegroundColor Gray
    
    if ($healthScore.Recommendations.Count -gt 0) {
        $healthScore.Recommendations | ForEach-Object {
            Write-Host "  • $_" -ForegroundColor Cyan
        }
    }
    
    # Performance insights
    if ($Results.StatisticsAnalysis) {
        $perfInsights = Get-PerformanceInsights -Statistics $Results.StatisticsAnalysis -Config @{ PerformanceThresholds = @{} }
        if ($perfInsights.Recommendations.Count -gt 0) {
            $perfInsights.Recommendations | ForEach-Object {
                Write-Host "  • $_" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "`n" -NoNewline
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "Report generated at: $(Get-Date)" -ForegroundColor Gray
}

function ConvertTo-SerializableObject {
    <#
    .SYNOPSIS
        Converts hashtables and complex objects to PSCustomObjects for JSON serialization.
    
    .PARAMETER InputObject
        The object to convert
    #>
    param(
        [Parameter(Mandatory = $true)]
        $InputObject
    )
    
    if ($InputObject -is [hashtable]) {
        $newObject = [PSCustomObject]@{}
        foreach ($key in $InputObject.Keys) {
            $value = if ($InputObject[$key] -is [hashtable] -or $InputObject[$key] -is [array]) {
                ConvertTo-SerializableObject -InputObject $InputObject[$key]
            } else {
                $InputObject[$key]
            }
            $newObject | Add-Member -MemberType NoteProperty -Name $key -Value $value
        }
        return $newObject
    }
    elseif ($InputObject -is [array]) {
        $newArray = @()
        foreach ($item in $InputObject) {
            $newArray += if ($item -is [hashtable] -or $item -is [array]) {
                ConvertTo-SerializableObject -InputObject $item
            } else {
                $item
            }
        }
        return $newArray
    }
    else {
        return $InputObject
    }
}

function New-JSONReport {
    <#
    .SYNOPSIS
        Generates a JSON report of the analysis results.
    
    .PARAMETER Results
        Analysis results from the main script
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Results
    )
    
    # Calculate health score and additional insights
    $healthScore = Get-HealthScore -AnalysisResults $Results
    
    $allIssues = @()
    foreach ($analysis in $Results.Values) {
        if ($analysis -is [hashtable] -and $analysis.ContainsKey("Issues")) {
            $allIssues += $analysis.Issues
        }
    }
    
    if ($allIssues.Count -eq 0) {
        $errorPatterns = @{}
        $trends = @{}
    } else {
        $errorPatterns = Get-ErrorPatterns -Issues $allIssues
        $trends = Get-TrendAnalysis -Issues $allIssues
    }
    
    # Get security and performance insights
    $securityAnalysis = if ($Results.SettingsAnalysis) {
        Get-SecurityAnalysis -Settings $Results.SettingsAnalysis -Issues $allIssues
    } else {
        @{}
    }
    
    $performanceInsights = if ($Results.StatisticsAnalysis) {
        Get-PerformanceInsights -Statistics $Results.StatisticsAnalysis -Config @{ PerformanceThresholds = @{} }
    } else {
        @{}
    }
    
    # Create report structure and convert all hashtables to PSCustomObjects
    $report = @{
        metadata = @{
            reportType = "RocketChat Support Dump Analysis"
            version = "1.0.0"
            generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            dumpPath = $Results.DumpPath
        }
        healthScore = $healthScore
        summary = $Results.Summary
        analysis = @{
            logs = $Results.LogAnalysis
            settings = $Results.SettingsAnalysis
            statistics = $Results.StatisticsAnalysis
            omnichannel = $Results.OmnichannelAnalysis
            apps = $Results.AppsAnalysis
        }
        insights = @{
            errorPatterns = $errorPatterns
            trends = $trends
            security = $securityAnalysis
            performance = $performanceInsights
        }
    }
    
    # Convert the entire report structure to be JSON-serializable
    $serializableReport = ConvertTo-SerializableObject -InputObject $report
    
    return ($serializableReport | ConvertTo-Json -Depth 10 -WarningAction SilentlyContinue)
}

function New-CSVReport {
    <#
    .SYNOPSIS
        Generates a CSV report of issues found in the analysis.
    
    .PARAMETER Results
        Analysis results from the main script
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Results
    )
    
    $csvData = @()
    
    foreach ($analysis in $Results.Values) {
        if ($analysis -is [hashtable] -and $analysis.ContainsKey("Issues")) {
            foreach ($issue in $analysis.Issues) {
                $csvData += [PSCustomObject]@{
                    Timestamp = if ($issue.Timestamp) { $issue.Timestamp } else { (Get-Date).ToString() }
                    Type = if ($issue.Type) { $issue.Type } else { "Unknown" }
                    Severity = if ($issue.Severity) { $issue.Severity } else { "Info" }
                    Message = if ($issue.Message) { $issue.Message } else { "" }
                    Pattern = if ($issue.Pattern) { $issue.Pattern } else { "" }
                    Setting = if ($issue.Setting) { $issue.Setting } else { "" }
                    Value = if ($issue.Value) { $issue.Value } else { "" }
                    Component = if ($issue.ContainsKey("Context")) { "Log" } 
                               elseif ($issue.ContainsKey("Setting")) { "Settings" }
                               elseif ($issue.ContainsKey("Metric")) { "Statistics" }
                               else { "General" }
                }
            }
        }
    }
    
    return $csvData
}

function New-HTMLReport {
    <#
    .SYNOPSIS
        Generates a comprehensive HTML report of RocketChat analysis results.
    
    .DESCRIPTION
        Creates a professional, interactive HTML report with:
        - Executive summary with health score and priority actions
        - Detailed analysis sections
        - Color-coded severity indicators
        - Component health breakdown
        - Security analysis and recommendations
        - Responsive design for various devices
    
    .PARAMETER Results
        Analysis results hashtable from the main script containing:
        - LogAnalysis, SettingsAnalysis, StatisticsAnalysis
        - OmnichannelAnalysis, AppsAnalysis
        - Summary information and timestamps
    
    .EXAMPLE
        $report = New-HTMLReport -Results $AnalysisResults
        $report | Out-File -FilePath "report.html" -Encoding UTF8
    
    .OUTPUTS
        String containing complete HTML report with embedded CSS and JavaScript
    
    .NOTES
        The generated HTML is self-contained with embedded styling and scripts.
        No external dependencies required for viewing.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Results
    )
    
    # Calculate health score
    try {
        $healthScore = Get-HealthScore -AnalysisResults $Results
    } catch {
        $healthScore = @{
            OverallScore = 0
            ComponentScores = @{}
            Issues = @{ Critical = 0; Error = 0; Warning = 0; Info = 0 }
            Recommendations = @("Unable to calculate health score")
        }
    }
    
    # Get current timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Count issues
    $allIssues = @()
    foreach ($analysis in $Results.Values) {
        if ($analysis -is [hashtable] -and $analysis.ContainsKey("Issues")) {
            $allIssues += $analysis.Issues
        }
    }
    
    $criticalCount = ($allIssues | Where-Object { $_.Severity -eq "Critical" }).Count
    $errorCount = ($allIssues | Where-Object { $_.Severity -eq "Error" }).Count
    $warningCount = ($allIssues | Where-Object { $_.Severity -eq "Warning" }).Count
    $infoCount = ($allIssues | Where-Object { $_.Severity -eq "Info" }).Count
    
    # Build HTML content
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RocketChat Support Dump Analysis Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .container { max-width: 1200px; margin: 0 auto; background: rgba(255,255,255,0.95); padding: 30px; border-radius: 15px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); backdrop-filter: blur(10px); }
        .header { text-align: center; background: linear-gradient(90deg, #007acc, #00a8ff); margin: -30px -30px 30px -30px; padding: 40px 30px; border-radius: 15px 15px 0 0; color: white; }
        .header h1 { color: white; margin: 0; font-size: 2.5em; text-shadow: 0 2px 4px rgba(0,0,0,0.3); }
        .health-score { display: flex; justify-content: space-around; margin: 30px 0; flex-wrap: wrap; }
        .health-item { text-align: center; padding: 25px; background: linear-gradient(135deg, #f8f9fa, #e9ecef); border-radius: 12px; min-width: 150px; margin: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
        .health-number { font-size: 2.8em; font-weight: bold; margin-bottom: 10px; }
        .health-number.good { color: #28a745; }
        .health-number.warning { color: #ffc107; }
        .health-number.critical { color: #dc3545; }
        .section { margin: 40px 0; padding: 25px; background: white; border-radius: 12px; box-shadow: 0 4px 8px rgba(0,0,0,0.05); }
        .section h2 { color: #495057; border-bottom: 3px solid #007bff; padding-bottom: 15px; margin-bottom: 20px; font-size: 1.8em; }
        .issue { margin: 15px 0; padding: 18px; border-left: 5px solid #17a2b8; background: #d1ecf1; border-radius: 0 8px 8px 0; }
        .issue.critical { border-left-color: #dc3545; background: linear-gradient(135deg, #f8d7da, #f1c2c7); }
        .issue.error { border-left-color: #dc3545; background: linear-gradient(135deg, #f8d7da, #f1c2c7); }
        .issue.warning { border-left-color: #ffc107; background: linear-gradient(135deg, #fff3cd, #fce4a6); }
        .issue.info { border-left-color: #17a2b8; background: linear-gradient(135deg, #d1ecf1, #b8d4da); }
        .footer { text-align: center; margin-top: 50px; padding-top: 30px; border-top: 2px solid #e9ecef; color: #6c757d; background: linear-gradient(135deg, #f8f9fa, #e9ecef); border-radius: 12px; padding: 30px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        th, td { padding: 15px; text-align: left; }
        th { background: linear-gradient(135deg, #007bff, #0056b3); color: white; font-weight: bold; }
        tr:nth-child(even) { background-color: #f8f9fa; }
        tr:hover { background-color: #e3f2fd; transition: background-color 0.3s; }
        .collapsible { cursor: pointer; background: #007bff; color: white; padding: 15px; border: none; width: 100%; text-align: left; font-size: 16px; border-radius: 8px; margin: 10px 0; }
        .collapsible:hover { background: #0056b3; }
        .collapsible.active { background: #0056b3; }
        .content { display: none; padding: 20px; background: #f8f9fa; border-radius: 0 0 8px 8px; }
        .badge { display: inline-block; padding: 6px 12px; border-radius: 20px; font-size: 0.9em; font-weight: bold; }
        .badge-success { background: #28a745; color: white; }
        .badge-warning { background: #ffc107; color: #212529; }
        .badge-danger { background: #dc3545; color: white; }
        .badge-info { background: #17a2b8; color: white; }
    </style>
    <script>
        function toggleCollapsible(element) {
            element.classList.toggle('active');
            var content = element.nextElementSibling;
            if (content.style.display === 'block') {
                content.style.display = 'none';
            } else {
                content.style.display = 'block';
            }
        }
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 RocketChat Analysis Report</h1>
            <p>Comprehensive Support Dump Analysis</p>
        </div>
        
        <div class="health-score">
            <div class="health-item">
                <div class="health-number good">$($healthScore.OverallScore)%</div>
                <div><strong>Overall Health</strong></div>
            </div>
            <div class="health-item">
                <div class="health-number critical">$criticalCount</div>
                <div><strong>Critical Issues</strong></div>
            </div>
            <div class="health-item">
                <div class="health-number critical">$errorCount</div>
                <div><strong>Errors</strong></div>
            </div>
            <div class="health-item">
                <div class="health-number warning">$warningCount</div>
                <div><strong>Warnings</strong></div>
            </div>
        </div>
"@


    # Always show Log Analysis section
    $htmlContent += @"
    <div class="section">
        <h2>📝 System Log Analysis</h2>
"@
    if ($Results.ContainsKey("LogAnalysis") -and $Results.LogAnalysis.ContainsKey("Summary")) {
        $logSummary = $Results.LogAnalysis.Summary
        $htmlContent += @"
        <table>
            <thead>
                <tr><th>Metric</th><th>Value</th><th>Status</th></tr>
            </thead>
            <tbody>
                <tr><td>Total Log Entries</td><td>$($logSummary.TotalEntries)</td><td><span class="badge badge-info">$($logSummary.TotalEntries)</span></td></tr>
                <tr><td>Error Messages</td><td>$($logSummary.ErrorCount)</td><td><span class="badge $(if($logSummary.ErrorCount -gt 0){'badge-danger'}else{'badge-success'})">$($logSummary.ErrorCount)</span></td></tr>
                <tr><td>Warning Messages</td><td>$($logSummary.WarningCount)</td><td><span class="badge $(if($logSummary.WarningCount -gt 10){'badge-warning'}else{'badge-success'})">$($logSummary.WarningCount)</span></td></tr>
                <tr><td>Info Messages</td><td>$($logSummary.InfoCount)</td><td><span class="badge badge-info">$($logSummary.InfoCount)</span></td></tr>
            </tbody>
        </table>
"@
    } else {
        $htmlContent += '<p><em>No log data found.</em></p>'
    }
    $htmlContent += '</div>'

    # Always show Settings Analysis section
    $htmlContent += @"
    <div class="section">
        <h2>⚙️ Configuration Analysis</h2>
"@
    if ($Results.ContainsKey("SettingsAnalysis") -and $Results.SettingsAnalysis.ContainsKey("Summary")) {
        $settingsSummary = $Results.SettingsAnalysis.Summary
        $htmlContent += @"
        <table>
            <thead>
                <tr><th>Metric</th><th>Value</th><th>Status</th></tr>
            </thead>
            <tbody>
                <tr><td>Total Settings Reviewed</td><td>$($settingsSummary.TotalSettings)</td><td><span class="badge badge-info">$($settingsSummary.TotalSettings)</span></td></tr>
                <tr><td>Security Issues</td><td>$($settingsSummary.SecurityIssues)</td><td><span class="badge $(if($settingsSummary.SecurityIssues -gt 0){'badge-danger'}else{'badge-success'})">$($settingsSummary.SecurityIssues)</span></td></tr>
                <tr><td>Performance Issues</td><td>$($settingsSummary.PerformanceIssues)</td><td><span class="badge $(if($settingsSummary.PerformanceIssues -gt 0){'badge-warning'}else{'badge-success'})">$($settingsSummary.PerformanceIssues)</span></td></tr>
                <tr><td>Configuration Warnings</td><td>$($settingsSummary.ConfigurationWarnings)</td><td><span class="badge $(if($settingsSummary.ConfigurationWarnings -gt 0){'badge-warning'}else{'badge-success'})">$($settingsSummary.ConfigurationWarnings)</span></td></tr>
            </tbody>
        </table>
"@
    } else {
        $htmlContent += '<p><em>No settings data found.</em></p>'
    }
    $htmlContent += '</div>'

    # Always show Statistics Analysis section
    $htmlContent += @"
    <div class="section">
        <h2>📊 Server Statistics</h2>
"@
    if ($Results.ContainsKey("StatisticsAnalysis") -and $Results.StatisticsAnalysis.ContainsKey("Summary")) {
        $statsSummary = $Results.StatisticsAnalysis.Summary
        $htmlContent += @"
        <table>
            <thead>
                <tr><th>Metric</th><th>Value</th><th>Details</th></tr>
            </thead>
            <tbody>
                <tr><td>RocketChat Version</td><td><strong>$($statsSummary.Version)</strong></td><td><span class="badge badge-info">Current</span></td></tr>
                <tr><td>Total Users</td><td>$($statsSummary.TotalUsers)</td><td><span class="badge badge-success">Active</span></td></tr>
                <tr><td>Online Users</td><td>$($statsSummary.OnlineUsers)</td><td><span class="badge badge-info">Now</span></td></tr>
                <tr><td>Total Messages</td><td>$($statsSummary.TotalMessages)</td><td><span class="badge badge-info">All Time</span></td></tr>
                <tr><td>Memory Usage</td><td>$($statsSummary.MemoryUsage)MB</td><td><span class="badge $(if($statsSummary.MemoryUsage -gt 8000){'badge-warning'}else{'badge-success'})">$(if($statsSummary.MemoryUsage -gt 8000){'High'}else{'Normal'})</span></td></tr>
            </tbody>
        </table>
"@
    } else {
        $htmlContent += '<p><em>No statistics data found.</em></p>'
    }
    $htmlContent += '</div>'

    # Always show Omnichannel Analysis section
    $htmlContent += @"
    <div class="section">
        <h2>💬 Omnichannel Configuration</h2>
"@
    if ($Results.ContainsKey("OmnichannelAnalysis") -and $Results.OmnichannelAnalysis) {
        $omni = $Results.OmnichannelAnalysis
        if ($omni.ContainsKey("Summary")) {
            $omniSummary = $omni.Summary
            $htmlContent += @"
            <table>
                <thead>
                    <tr><th>Metric</th><th>Value</th></tr>
                </thead>
                <tbody>
                    <tr><td>Total Departments</td><td>$($omniSummary.TotalDepartments)</td></tr>
                    <tr><td>Active Agents</td><td>$($omniSummary.ActiveAgents)</td></tr>
                    <tr><td>Enabled Features</td><td>$($omniSummary.EnabledFeatures -join ', ')</td></tr>
                </tbody>
            </table>
"@
        } else {
            $htmlContent += '<p><em>No omnichannel summary data found.</em></p>'
        }
    } else {
        $htmlContent += '<p><em>No omnichannel data found.</em></p>'
    }
    $htmlContent += '</div>'

    # Always show Apps Analysis section
    $htmlContent += @"
    <div class="section">
        <h2>🧩 Installed Apps & Integrations</h2>
"@
    if ($Results.ContainsKey("AppsAnalysis") -and $Results.AppsAnalysis) {
        $apps = $Results.AppsAnalysis
        if ($apps.ContainsKey("Summary")) {
            $appsSummary = $apps.Summary
            $htmlContent += @"
            <table>
                <thead>
                    <tr><th>App Name</th><th>Version</th><th>Status</th></tr>
                </thead>
                <tbody>
                    $(foreach ($app in $appsSummary.Apps) { "<tr><td>$($app.Name)</td><td>$($app.Version)</td><td>$($app.Status)</td></tr>" })
                </tbody>
            </table>
"@
        } else {
            $htmlContent += '<p><em>No apps summary data found.</em></p>'
        }
    } else {
        $htmlContent += '<p><em>No apps data found.</em></p>'
    }
    $htmlContent += '</div>'

    # Add top issues section
    if ($allIssues.Count -gt 0) {
        $htmlContent += @"
        
        <div class="section">
            <h2>🔍 Issue Summary (Top 20)</h2>
            <button class="collapsible" onclick="toggleCollapsible(this)">View All Issues ($($allIssues.Count) total)</button>
            <div class="content">
"@
        
        foreach ($issue in ($allIssues | Select-Object -First 20)) {
            $severityClass = $issue.Severity.ToLower()
            $issueMessage = $issue.Message -replace '"', '&quot;' -replace '<', '&lt;' -replace '>', '&gt;'
            $htmlContent += @"
                <div class="issue $severityClass">
                    <strong>[$($issue.Severity.ToUpper())]</strong> $issueMessage
                    $(if ($issue.Timestamp) { "<br><small><em>Time: $($issue.Timestamp)</em></small>" })
                    $(if ($issue.Context) { "<br><small><em>Context: $($issue.Context)</em></small>" })
                </div>
"@
        }
        
        $htmlContent += @"
            </div>
        </div>
"@
    }

    # Add recommendations
    if ($healthScore.Recommendations -and $healthScore.Recommendations.Count -gt 0) {
        $htmlContent += @"
        
        <div class="section">
            <h2>💡 Recommendations & Action Items</h2>
"@
        $recIndex = 1
        foreach ($rec in $healthScore.Recommendations) {
            $recText = $rec -replace '"', '&quot;' -replace '<', '&lt;' -replace '>', '&gt;'
            $htmlContent += "            <div class='issue info'><strong>${recIndex}:</strong> $recText</div>`n"
            $recIndex++
        }
        $htmlContent += "        </div>"
    }

    # Add footer
    $htmlContent += @"
        
        <div class="footer">
            <h3>🛠️ Analysis Report Details</h3>
            <p><strong>Tool Version:</strong> RocketChat Support Dump Analyzer v1.4.8 (PowerShell)</p>
            <p><strong>Generated:</strong> $timestamp</p>
            <p><strong>Total Issues Found:</strong> $($allIssues.Count)</p>
            <p><strong>Overall Health Score:</strong> $($healthScore.OverallScore)%</p>
            <p><em>This report provides a comprehensive analysis of your RocketChat support dump.<br>
            For technical support or questions about this analysis, contact your system administrator.</em></p>
        </div>
    </div>
</body>
</html>
"@

    return $htmlContent
}

Export-ModuleMember -Function Write-ConsoleReport, New-JSONReport, New-CSVReport, New-HTMLReport
