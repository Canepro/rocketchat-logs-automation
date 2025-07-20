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
        
        # Platform Information
        if ($Results.StatisticsAnalysis.PlatformInfo) {
            $platform = $Results.StatisticsAnalysis.PlatformInfo
            Write-Host "`nPlatform Information:" -ForegroundColor Cyan
            Write-Host "  Deployment: $($platform.DeploymentType)" -ForegroundColor Gray
            Write-Host "  OS: $($platform.OS)" -ForegroundColor Gray
            Write-Host "  Node Version: $($platform.NodeVersion)" -ForegroundColor Gray
            Write-Host "  Database: $($platform.DatabaseType)" -ForegroundColor Gray
        }
        
        # Performance Metrics
        if ($Results.StatisticsAnalysis.PerformanceMetrics) {
            $perf = $Results.StatisticsAnalysis.PerformanceMetrics
            
            if ($perf.Memory) {
                $memMB = [math]::Round($perf.Memory.Used / 1024 / 1024, 2)
                $heapMB = [math]::Round($perf.Memory.Heap / 1024 / 1024, 2)
                Write-Host "`nMemory Usage:" -ForegroundColor Cyan
                Write-Host "  RSS Memory: ${memMB}MB" -ForegroundColor $(if ($memMB -gt 4096) { "Red" } elseif ($memMB -gt 2048) { "Yellow" } else { "Green" })
                Write-Host "  Heap Used: ${heapMB}MB" -ForegroundColor Gray
            }
        }
        
        # User Metrics
        if ($Results.StatisticsAnalysis.UserMetrics) {
            $users = $Results.StatisticsAnalysis.UserMetrics
            Write-Host "`nUser Metrics:" -ForegroundColor Cyan
            Write-Host "  Total Users: $($users.Total)" -ForegroundColor White
            Write-Host "  Online: $($users.Online) ($($users.OnlinePercentage)%)" -ForegroundColor $(if ($users.Online -gt 1000) { "Yellow" } else { "Green" })
            Write-Host "  Away: $($users.Away)" -ForegroundColor Gray
            Write-Host "  Offline: $($users.Offline)" -ForegroundColor Gray
        }
        
        # Message Metrics
        if ($Results.StatisticsAnalysis.MessageMetrics) {
            $messages = $Results.StatisticsAnalysis.MessageMetrics
            Write-Host "`nMessage Metrics:" -ForegroundColor Cyan
            Write-Host "  Total Messages: $($messages.Total)" -ForegroundColor White
            Write-Host "  Channels: $($messages.Channels)" -ForegroundColor Gray
            Write-Host "  Private Groups: $($messages.PrivateGroups)" -ForegroundColor Gray
            Write-Host "  Direct Messages: $($messages.DirectMessages)" -ForegroundColor Gray
            if ($messages.LivechatSessions -gt 0) {
                Write-Host "  Livechat Sessions: $($messages.LivechatSessions)" -ForegroundColor Gray
            }
        }
        
        # Resource Usage
        if ($Results.StatisticsAnalysis.ResourceUsage) {
            $resources = $Results.StatisticsAnalysis.ResourceUsage
            Write-Host "`nResource Usage:" -ForegroundColor Cyan
            
            if ($resources.Database) {
                $db = $resources.Database
                $dataSizeGB = [math]::Round($db.DataSize / 1024 / 1024 / 1024, 2)
                Write-Host "  Database Size: ${dataSizeGB}GB" -ForegroundColor $(if ($dataSizeGB -gt 100) { "Yellow" } else { "Green" })
                Write-Host "  Collections: $($db.Collections)" -ForegroundColor Gray
                Write-Host "  Documents: $($db.Objects)" -ForegroundColor Gray
            }
            
            if ($resources.Uploads) {
                $uploads = $resources.Uploads
                $uploadSizeGB = [math]::Round($uploads.TotalSize / 1024 / 1024 / 1024, 2)
                Write-Host "  File Uploads: $($uploads.Total) files (${uploadSizeGB}GB)" -ForegroundColor Gray
            }
            
            if ($resources.Apps) {
                $apps = $resources.Apps
                Write-Host "  Apps: $($apps.EnabledApps)/$($apps.TotalApps) enabled" -ForegroundColor Gray
                if ($apps.Integrations -gt 0) {
                    Write-Host "  Integrations: $($apps.Integrations)" -ForegroundColor Gray
                }
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
    
    try {
        # Calculate health score and additional insights
        $healthScore = Get-HealthScore -AnalysisResults $Results
        
        $allIssues = @()
        foreach ($analysis in $Results.Values) {
            if ($analysis -is [hashtable] -and $analysis.ContainsKey("Issues")) {
                $allIssues += $analysis.Issues
            }
        }
        
        # Convert hashtables to PSCustomObjects for proper JSON serialization
        $report = [PSCustomObject]@{
            metadata = [PSCustomObject]@{
                reportType = "RocketChat Support Dump Analysis"
                version = "1.2.0"
                generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                dumpPath = $Results.DumpPath
                analysisEngine = "RocketChat Log Automation v1.2.0"
            }
            healthScore = [PSCustomObject]@{
                overallScore = $healthScore.OverallScore
                componentScores = [PSCustomObject]@{
                    logs = $healthScore.ComponentScores.Logs
                    settings = $healthScore.ComponentScores.Settings
                    performance = $healthScore.ComponentScores.Performance
                    security = $healthScore.ComponentScores.Security
                }
                issues = [PSCustomObject]@{
                    critical = $healthScore.Issues.Critical
                    error = $healthScore.Issues.Error
                    warning = $healthScore.Issues.Warning
                    info = $healthScore.Issues.Info
                }
                recommendations = $healthScore.Recommendations
            }
            summary = [PSCustomObject]@{
                totalIssues = $Results.Summary.TotalIssues
                criticalIssues = $Results.Summary.CriticalIssues
                errorIssues = $Results.Summary.ErrorIssues
                warningIssues = $Results.Summary.WarningIssues
                infoIssues = $Results.Summary.InfoIssues
            }
            analysis = [PSCustomObject]@{
                logs = if ($Results.LogAnalysis) { ConvertTo-SerializableObject $Results.LogAnalysis } else { $null }
                settings = if ($Results.SettingsAnalysis) { ConvertTo-SerializableObject $Results.SettingsAnalysis } else { $null }
                statistics = if ($Results.StatisticsAnalysis) { ConvertTo-SerializableObject $Results.StatisticsAnalysis } else { $null }
                omnichannel = if ($Results.OmnichannelAnalysis) { ConvertTo-SerializableObject $Results.OmnichannelAnalysis } else { $null }
                apps = if ($Results.AppsAnalysis) { ConvertTo-SerializableObject $Results.AppsAnalysis } else { $null }
            }
            insights = [PSCustomObject]@{
                errorPatterns = ConvertTo-SerializableObject (Get-ErrorPatterns -Issues $allIssues)
                trends = ConvertTo-SerializableObject (Get-TrendAnalysis -Issues $allIssues)
            }
        }
        
        # Add security analysis if settings are available
        if ($Results.SettingsAnalysis) {
            $securityAnalysis = Get-SecurityAnalysis -Settings $Results.SettingsAnalysis -Issues $allIssues
            $report.insights | Add-Member -NotePropertyName "security" -NotePropertyValue (ConvertTo-SerializableObject $securityAnalysis)
        }
        
        # Add performance insights if statistics are available
        if ($Results.StatisticsAnalysis) {
            $perfInsights = Get-PerformanceInsights -Statistics $Results.StatisticsAnalysis -Config @{ PerformanceThresholds = @{} }
            $report.insights | Add-Member -NotePropertyName "performance" -NotePropertyValue (ConvertTo-SerializableObject $perfInsights)
        }
        
        return ($report | ConvertTo-Json -Depth 10)
        
    } catch {
        Write-Error "Error generating JSON report: $($_.Exception.Message)"
        # Return a minimal error report
        $errorReport = [PSCustomObject]@{
            metadata = [PSCustomObject]@{
                reportType = "RocketChat Support Dump Analysis (Error)"
                version = "1.2.0"
                generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                error = $_.Exception.Message
            }
            summary = [PSCustomObject]@{
                totalIssues = if ($Results.Summary) { $Results.Summary.TotalIssues } else { 0 }
            }
        }
        return ($errorReport | ConvertTo-Json -Depth 5)
    }
}

function ConvertTo-SerializableObject {
    <#
    .SYNOPSIS
        Converts hashtables and complex objects to PSCustomObjects for JSON serialization.
    #>
    param(
        [Parameter(Mandatory = $true)]
        $InputObject
    )
    
    if ($InputObject -is [hashtable]) {
        $result = [PSCustomObject]@{}
        foreach ($key in $InputObject.Keys) {
            $value = if ($InputObject[$key] -is [hashtable] -or $InputObject[$key] -is [array]) {
                ConvertTo-SerializableObject $InputObject[$key]
            } else {
                $InputObject[$key]
            }
            $result | Add-Member -NotePropertyName $key -NotePropertyValue $value
        }
        return $result
    } elseif ($InputObject -is [array]) {
        return @($InputObject | ForEach-Object { ConvertTo-SerializableObject $_ })
    } else {
        return $InputObject
    }
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
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .container { max-width: 1200px; margin: 20px auto; background-color: white; border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.12); overflow: hidden; }
        .header { background: linear-gradient(135deg, #007acc 0%, #0056b3 100%); color: white; text-align: center; padding: 30px 20px; }
        .header h1 { margin: 0; font-size: 2.5em; font-weight: 300; text-shadow: 0 2px 4px rgba(0,0,0,0.3); }
        .header .subtitle { font-size: 1.1em; margin-top: 10px; opacity: 0.9; }
        .content { padding: 30px; }
        .section { margin-bottom: 40px; }
        .section h2 { color: #333; border-left: 5px solid #007acc; padding-left: 20px; margin-bottom: 25px; font-size: 1.8em; font-weight: 400; }
        .health-score { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 30px 0; }
        .score-card { background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%); padding: 25px; border-radius: 12px; text-align: center; box-shadow: 0 4px 12px rgba(0,0,0,0.08); transition: transform 0.2s ease; }
        .score-card:hover { transform: translateY(-2px); }
        .score-excellent { background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%); border: 2px solid #28a745; }
        .score-good { background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%); border: 2px solid #ffc107; }
        .score-poor { background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%); border: 2px solid #dc3545; }
        .score-number { font-size: 3em; font-weight: bold; margin: 10px 0; line-height: 1; }
        .score-label { font-size: 1.1em; font-weight: 500; color: #555; text-transform: uppercase; letter-spacing: 0.5px; }
        .issue-list { list-style: none; padding: 0; margin: 20px 0; }
        .issue-item { padding: 15px 20px; margin: 8px 0; border-radius: 8px; border-left: 5px solid; box-shadow: 0 2px 8px rgba(0,0,0,0.06); transition: all 0.2s ease; }
        .issue-item:hover { transform: translateX(5px); box-shadow: 0 4px 16px rgba(0,0,0,0.12); }
        .issue-critical { background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%); border-left-color: #dc3545; }
        .issue-error { background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%); border-left-color: #dc3545; }
        .issue-warning { background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%); border-left-color: #ffc107; }
        .issue-info { background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%); border-left-color: #17a2b8; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; margin: 25px 0; }
        .stat-card { background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%); padding: 20px; border-radius: 10px; border: 1px solid #dee2e6; box-shadow: 0 3px 10px rgba(0,0,0,0.05); }
        .stat-card h4 { margin: 0 0 15px 0; color: #007acc; font-size: 1.2em; }
        .progress-bar { width: 100%; height: 8px; background-color: #e9ecef; border-radius: 4px; overflow: hidden; margin: 10px 0; }
        .progress-fill { height: 100%; transition: width 0.3s ease; border-radius: 4px; }
        .progress-excellent { background: linear-gradient(90deg, #28a745, #20c997); }
        .progress-good { background: linear-gradient(90deg, #ffc107, #fd7e14); }
        .progress-poor { background: linear-gradient(90deg, #dc3545, #e74c3c); }
        .timestamp { color: #6c757d; font-size: 0.95em; font-style: italic; }
        .recommendations { background: linear-gradient(135deg, #e7f3ff 0%, #d4e9f7 100%); padding: 20px; border-radius: 10px; border-left: 5px solid #007acc; margin: 20px 0; }
        .recommendations h3 { margin-top: 0; color: #007acc; }
        .badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 0.85em; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px; }
        .badge-critical { background-color: #dc3545; color: white; }
        .badge-error { background-color: #dc3545; color: white; }
        .badge-warning { background-color: #ffc107; color: #212529; }
        .badge-info { background-color: #17a2b8; color: white; }
        .table-container { overflow-x: auto; margin: 20px 0; }
        table { width: 100%; border-collapse: collapse; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }
        th { background: linear-gradient(135deg, #007acc 0%, #0056b3 100%); color: white; padding: 15px 12px; font-weight: 500; text-align: left; }
        td { padding: 12px; border-bottom: 1px solid #dee2e6; }
        .chart-container { background: white; border-radius: 8px; padding: 20px; margin: 20px 0; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }
        .summary-stats { display: flex; justify-content: space-around; flex-wrap: wrap; margin: 20px 0; }
        .summary-stat { text-align: center; margin: 10px; }
        .summary-stat .number { font-size: 2.5em; font-weight: bold; color: #007acc; display: block; }
        .summary-stat .label { color: #6c757d; font-size: 0.9em; text-transform: uppercase; letter-spacing: 0.5px; }
        @media (max-width: 768px) {
            .container { margin: 10px; border-radius: 8px; }
            .header { padding: 20px 15px; }
            .header h1 { font-size: 2em; }
            .content { padding: 20px 15px; }
            .health-score { grid-template-columns: 1fr; }
            .stats-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 RocketChat Support Dump Analysis Report</h1>
            <div class="subtitle">Comprehensive System Health Analysis</div>
            <p class="timestamp">Generated on $(Get-Date -Format "MMMM dd, yyyy 'at' HH:mm:ss")</p>
            <p><strong>Dump Path:</strong> $($Results.DumpPath)</p>
        </div>
        
        <div class="content">
            <div class="section">
                <h2>📊 Health Overview</h2>
                <div class="health-score">
                    <div class="score-card $(if ($healthScore.OverallScore -ge 90) { 'score-excellent' } elseif ($healthScore.OverallScore -ge 70) { 'score-good' } else { 'score-poor' })">
                        <div class="score-label">Overall Health</div>
                        <div class="score-number">$($healthScore.OverallScore)%</div>
                        <div class="progress-bar">
                            <div class="progress-fill $(if ($healthScore.OverallScore -ge 90) { 'progress-excellent' } elseif ($healthScore.OverallScore -ge 70) { 'progress-good' } else { 'progress-poor' })" style="width: $($healthScore.OverallScore)%"></div>
                        </div>
                    </div>
                    <div class="score-card">
                        <div class="score-label">Total Issues</div>
                        <div class="score-number">$($Results.Summary.TotalIssues)</div>
                        <div style="font-size: 0.9em; color: #6c757d;">Across all components</div>
                    </div>
                    <div class="score-card $(if ($healthScore.Issues.Critical -eq 0) { 'score-excellent' } else { 'score-poor' })">
                        <div class="score-label">Critical Issues</div>
                        <div class="score-number" style="color: #dc3545;">$($healthScore.Issues.Critical)</div>
                        <div style="font-size: 0.9em; color: #6c757d;">Immediate attention required</div>
                    </div>
                </div>
                
                <div class="summary-stats">
                    <div class="summary-stat">
                        <span class="number">$($healthScore.Issues.Error)</span>
                        <span class="label">Errors</span>
                    </div>
                    <div class="summary-stat">
                        <span class="number">$($healthScore.Issues.Warning)</span>
                        <span class="label">Warnings</span>
                    </div>
                    <div class="summary-stat">
                        <span class="number">$($healthScore.Issues.Info)</span>
                        <span class="label">Info</span>
                    </div>
                </div>
                
                <div class="stats-grid">
                    <div class="stat-card">
                        <h4>Component Health Scores</h4>
$(foreach ($component in $healthScore.ComponentScores.GetEnumerator()) {
    $progressClass = if ($component.Value -ge 90) { 'progress-excellent' } elseif ($component.Value -ge 70) { 'progress-good' } else { 'progress-poor' }
    "                        <div style='margin: 10px 0;'>
                            <div style='display: flex; justify-content: space-between; margin-bottom: 5px;'>
                                <span>$($component.Key)</span>
                                <span style='font-weight: bold;'>$($component.Value)%</span>
                            </div>
                            <div class='progress-bar'>
                                <div class='progress-fill $progressClass' style='width: $($component.Value)%'></div>
                            </div>
                        </div>"
})
                    </div>
                    <div class="stat-card">
                        <h4>Issues by Severity</h4>
                        <div style="margin: 10px 0;">
                            <span class="badge badge-critical">Critical: $($healthScore.Issues.Critical)</span>
                        </div>
                        <div style="margin: 10px 0;">
                            <span class="badge badge-error">Error: $($healthScore.Issues.Error)</span>
                        </div>
                        <div style="margin: 10px 0;">
                            <span class="badge badge-warning">Warning: $($healthScore.Issues.Warning)</span>
                        </div>
                        <div style="margin: 10px 0;">
                            <span class="badge badge-info">Info: $($healthScore.Issues.Info)</span>
                        </div>
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
                    <h3>Suggested Actions</h3>
                    <ul>
$(foreach ($rec in $healthScore.Recommendations) {
    "                        <li>$rec</li>"
})
$(if ($securityAnalysis.Recommendations) {
    foreach ($rec in $securityAnalysis.Recommendations) {
        "                        <li>$rec</li>"
    }
})
                    </ul>
                </div>
            </div>
            
            <div class="section">
                <h2>📋 Analysis Summary</h2>
                <div class="stat-card">
                    <p><strong>Analysis completed successfully!</strong></p>
                    <p>This report provides a comprehensive overview of your RocketChat instance health and performance.</p>
                    <p>For detailed raw data analysis, please export to JSON format or contact your support team.</p>
                    <div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #dee2e6; color: #6c757d; font-size: 0.9em;">
                        <p><strong>Report Details:</strong></p>
                        <p>• Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
                        <p>• Analysis Engine: RocketChat Log Automation v1.2.0</p>
                        <p>• Dump Path: $($Results.DumpPath)</p>
                    </div>
                </div>
            </div>
        </div> <!-- Close content div -->
    </div>
</body>
</html>
"@

    return $html
}

Export-ModuleMember -Function Write-ConsoleReport, New-JSONReport, New-CSVReport, New-HTMLReport
