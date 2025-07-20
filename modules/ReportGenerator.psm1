<#
.SYNOPSIS
    Report Generator Module - Functions for generating various report formats.

.DESCRIPTION
    This module provides functions to generate reports in different formats including
    console output, JSON, CSV, and HTML reports.
#>

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
        $filteredIssues = $Results.LogAnalysis.Issues | Where-Object { $severityLevels[$_.Severity] -ge $minLevel }
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
        
        $filteredSettingsIssues = $Results.SettingsAnalysis.Issues | Where-Object { $severityLevels[$_.Severity] -ge $minLevel }
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
        
        $filteredStatsIssues = $Results.StatisticsAnalysis.Issues | Where-Object { $severityLevels[$_.Severity] -ge $minLevel }
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
    
    $errorPatterns = Get-ErrorPatterns -Issues $allIssues
    $trends = Get-TrendAnalysis -Issues $allIssues
    
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
        }
    }
    
    # Add security analysis if settings are available
    if ($Results.SettingsAnalysis) {
        $report.insights.security = Get-SecurityAnalysis -Settings $Results.SettingsAnalysis -Issues $allIssues
    }
    
    # Add performance insights if statistics are available
    if ($Results.StatisticsAnalysis) {
        $report.insights.performance = Get-PerformanceInsights -Statistics $Results.StatisticsAnalysis -Config @{ PerformanceThresholds = @{} }
    }
    
    return ($report | ConvertTo-Json -Depth 10)
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
                    Timestamp = $issue.Timestamp ?? (Get-Date).ToString()
                    Type = $issue.Type ?? "Unknown"
                    Severity = $issue.Severity ?? "Info"
                    Message = $issue.Message ?? ""
                    Pattern = $issue.Pattern ?? ""
                    Setting = $issue.Setting ?? ""
                    Value = $issue.Value ?? ""
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
        Generates an HTML report of the analysis results.
    
    .PARAMETER Results
        Analysis results from the main script
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Results
    )
    
    # Calculate health score and insights
    $healthScore = Get-HealthScore -AnalysisResults $Results
    
    $allIssues = @()
    foreach ($analysis in $Results.Values) {
        if ($analysis -is [hashtable] -and $analysis.ContainsKey("Issues")) {
            $allIssues += $analysis.Issues
        }
    }
    
    $securityAnalysis = if ($Results.SettingsAnalysis) { 
        Get-SecurityAnalysis -Settings $Results.SettingsAnalysis -Issues $allIssues 
    } else { @{} }
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RocketChat Support Dump Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { text-align: center; color: #333; border-bottom: 2px solid #007acc; padding-bottom: 20px; margin-bottom: 30px; }
        .header h1 { color: #007acc; margin: 0; }
        .section { margin-bottom: 30px; }
        .section h2 { color: #333; border-left: 4px solid #007acc; padding-left: 15px; }
        .health-score { display: flex; justify-content: space-around; text-align: center; margin: 20px 0; }
        .score-card { background-color: #f8f9fa; padding: 20px; border-radius: 8px; min-width: 150px; }
        .score-excellent { background-color: #d4edda; border-left: 4px solid #28a745; }
        .score-good { background-color: #fff3cd; border-left: 4px solid #ffc107; }
        .score-poor { background-color: #f8d7da; border-left: 4px solid #dc3545; }
        .issue-list { list-style: none; padding: 0; }
        .issue-item { padding: 10px; margin: 5px 0; border-radius: 4px; border-left: 4px solid; }
        .issue-critical { background-color: #f8d7da; border-left-color: #dc3545; }
        .issue-error { background-color: #f8d7da; border-left-color: #dc3545; }
        .issue-warning { background-color: #fff3cd; border-left-color: #ffc107; }
        .issue-info { background-color: #d1ecf1; border-left-color: #17a2b8; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
        .stat-card { background-color: #f8f9fa; padding: 15px; border-radius: 8px; border: 1px solid #dee2e6; }
        .timestamp { color: #6c757d; font-size: 0.9em; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; font-weight: bold; }
        .recommendations { background-color: #e7f3ff; padding: 15px; border-radius: 8px; border-left: 4px solid #007acc; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 RocketChat Support Dump Analysis Report</h1>
            <p class="timestamp">Generated on $(Get-Date -Format "MMMM dd, yyyy 'at' HH:mm:ss")</p>
            <p><strong>Dump Path:</strong> $($Results.DumpPath)</p>
        </div>
        
        <div class="section">
            <h2>📊 Health Overview</h2>
            <div class="health-score">
                <div class="score-card $(if ($healthScore.OverallScore -ge 90) { 'score-excellent' } elseif ($healthScore.OverallScore -ge 70) { 'score-good' } else { 'score-poor' })">
                    <h3>Overall Health</h3>
                    <div style="font-size: 2em; font-weight: bold;">$($healthScore.OverallScore)%</div>
                </div>
                <div class="score-card">
                    <h3>Total Issues</h3>
                    <div style="font-size: 2em; font-weight: bold;">$($Results.Summary.TotalIssues)</div>
                </div>
                <div class="score-card">
                    <h3>Critical Issues</h3>
                    <div style="font-size: 2em; font-weight: bold; color: #dc3545;">$($healthScore.Issues.Critical)</div>
                </div>
            </div>
            
            <div class="stats-grid">
                <div class="stat-card">
                    <h4>Component Health</h4>
                    <ul style="list-style: none; padding: 0;">
$(foreach ($component in $healthScore.ComponentScores.GetEnumerator()) {
    $color = if ($component.Value -ge 90) { "#28a745" } elseif ($component.Value -ge 70) { "#ffc107" } else { "#dc3545" }
    "                        <li style='color: $color;'>• $($component.Key): $($component.Value)%</li>"
})
                    </ul>
                </div>
                <div class="stat-card">
                    <h4>Issues by Severity</h4>
                    <ul style="list-style: none; padding: 0;">
                        <li style="color: #dc3545;">• Critical: $($healthScore.Issues.Critical)</li>
                        <li style="color: #dc3545;">• Error: $($healthScore.Issues.Error)</li>
                        <li style="color: #ffc107;">• Warning: $($healthScore.Issues.Warning)</li>
                        <li style="color: #17a2b8;">• Info: $($healthScore.Issues.Info)</li>
                    </ul>
                </div>
            </div>
        </div>
"@

    # Add log analysis section
    if ($Results.LogAnalysis -and $Results.LogAnalysis.Issues) {
        $html += @"
        <div class="section">
            <h2>📝 Log Analysis</h2>
            <div class="stats-grid">
                <div class="stat-card">
                    <h4>Log Summary</h4>
                    <p><strong>Total Entries:</strong> $($Results.LogAnalysis.Summary.TotalEntries)</p>
                    <p><strong>Errors:</strong> $($Results.LogAnalysis.Summary.ErrorCount)</p>
                    <p><strong>Warnings:</strong> $($Results.LogAnalysis.Summary.WarningCount)</p>
                    <p><strong>Info:</strong> $($Results.LogAnalysis.Summary.InfoCount)</p>
                </div>
$(if ($Results.LogAnalysis.TimeRange.Start) {
"                <div class='stat-card'>
                    <h4>Time Range</h4>
                    <p><strong>From:</strong> $($Results.LogAnalysis.TimeRange.Start)</p>
                    <p><strong>To:</strong> $($Results.LogAnalysis.TimeRange.End)</p>
                </div>"
})
            </div>
            
            <h3>Issues Found</h3>
            <ul class="issue-list">
$(foreach ($issue in ($Results.LogAnalysis.Issues | Select-Object -First 20)) {
    $cssClass = "issue-" + $issue.Severity.ToLower()
    "                <li class='issue-item $cssClass'>
                    <strong>[$($issue.Severity)]</strong> $($issue.Message)
                    $(if ($issue.Timestamp) { "<br><small>Time: $($issue.Timestamp)</small>" })
                </li>"
})
            </ul>
        </div>
"@
    }

    # Add security analysis section
    if ($securityAnalysis -and $securityAnalysis.SecurityScore) {
        $html += @"
        <div class="section">
            <h2>🔒 Security Analysis</h2>
            <div class="score-card $(if ($securityAnalysis.SecurityScore -ge 90) { 'score-excellent' } elseif ($securityAnalysis.SecurityScore -ge 70) { 'score-good' } else { 'score-poor' })">
                <h3>Security Score: $($securityAnalysis.SecurityScore)%</h3>
            </div>
            
$(if ($securityAnalysis.SecurityIssues.Count -gt 0) {
"            <h3>Security Issues</h3>
            <ul class='issue-list'>
$(foreach ($issue in $securityAnalysis.SecurityIssues) {
    "                <li class='issue-item issue-warning'>• $issue</li>"
})
            </ul>"
})
        </div>
"@
    }

    # Add recommendations section
    $html += @"
        <div class="section">
            <h2>💡 Recommendations</h2>
            <div class="recommendations">
                <ul>
$(foreach ($rec in $healthScore.Recommendations) {
    "                    <li>$rec</li>"
})
$(if ($securityAnalysis.Recommendations) {
    foreach ($rec in $securityAnalysis.Recommendations) {
        "                    <li>$rec</li>"
    }
})
                </ul>
            </div>
        </div>
        
        <div class="section">
            <h2>📋 Detailed Analysis Data</h2>
            <p>For detailed analysis data, please refer to the JSON export or contact your support team.</p>
        </div>
    </div>
</body>
</html>
"@

    return $html
}

Export-ModuleMember -Function Write-ConsoleReport, New-JSONReport, New-CSVReport, New-HTMLReport
