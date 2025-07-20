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
    
    # Convert to PSCustomObject to ensure proper JSON serialization
    $report = [PSCustomObject]@{
        metadata = [PSCustomObject]@{
            reportType = "RocketChat Support Dump Analysis"
            version = "1.0.0"
            generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            dumpPath = $Results.DumpPath
        }
        healthScore = $healthScore
        summary = $Results.Summary
        analysis = [PSCustomObject]@{
            logs = $Results.LogAnalysis
            settings = $Results.SettingsAnalysis
            statistics = $Results.StatisticsAnalysis
            omnichannel = $Results.OmnichannelAnalysis
            apps = $Results.AppsAnalysis
        }
        insights = [PSCustomObject]@{
            errorPatterns = $errorPatterns
            trends = $trends
        }
    }
    
    # Add security analysis if settings are available
    if ($Results.SettingsAnalysis) {
        $report.insights | Add-Member -MemberType NoteProperty -Name "security" -Value (Get-SecurityAnalysis -Settings $Results.SettingsAnalysis -Issues $allIssues)
    }
    
    # Add performance insights if statistics are available
    if ($Results.StatisticsAnalysis) {
        $report.insights | Add-Member -MemberType NoteProperty -Name "performance" -Value (Get-PerformanceInsights -Statistics $Results.StatisticsAnalysis -Config @{ PerformanceThresholds = @{} })
    }
    
    return ($report | ConvertTo-Json -Depth 10 -WarningAction SilentlyContinue)
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
    
    $securityAnalysis = if ($Results.SettingsAnalysis -and $allIssues.Count -gt 0) { 
        Get-SecurityAnalysis -Settings $Results.SettingsAnalysis -Issues $allIssues 
    } elseif ($Results.SettingsAnalysis) {
        Get-SecurityAnalysis -Settings $Results.SettingsAnalysis -Issues @()
    } else { 
        @{} 
    }
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RocketChat Support Dump Analysis Report</title>
    <style>
        /* Modern gradient background and typography */
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            background: rgba(255,255,255,0.95); 
            padding: 30px; 
            border-radius: 15px; 
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            backdrop-filter: blur(10px);
        }
        
        /* Enhanced header with gradient */
        .header { 
            text-align: center; 
            color: #333; 
            background: linear-gradient(90deg, #007acc, #00a8ff);
            margin: -30px -30px 30px -30px;
            padding: 40px 30px;
            border-radius: 15px 15px 0 0;
            color: white;
        }
        .header h1 { 
            color: white; 
            margin: 0; 
            font-size: 2.5em;
            text-shadow: 0 2px 4px rgba(0,0,0,0.3);
        }
        
        /* Collapsible sections with animation */
        .section { 
            margin-bottom: 30px; 
            border-radius: 10px;
            overflow: hidden;
        }
        .section h2 { 
            color: #333; 
            border-left: 4px solid #007acc; 
            padding: 15px;
            margin: 0;
            background: linear-gradient(90deg, #f8f9fa, #e9ecef);
            cursor: pointer;
            transition: all 0.3s ease;
            user-select: none;
        }
        .section h2:hover {
            background: linear-gradient(90deg, #e9ecef, #dee2e6);
            transform: translateX(5px);
        }
        .section-content {
            padding: 20px;
            border: 1px solid #dee2e6;
            border-top: none;
        }
        .collapsible .section-content {
            display: none;
        }
        
        /* Enhanced health score cards */
        .health-score { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
            gap: 20px; 
            margin: 20px 0; 
        }
        .score-card { 
            background: linear-gradient(135deg, #f8f9fa, #ffffff); 
            padding: 25px; 
            border-radius: 15px; 
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            border: 2px solid transparent;
        }
        .score-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 35px rgba(0,0,0,0.15);
        }
        .score-excellent { 
            background: linear-gradient(135deg, #d4edda, #c3e6cb); 
            border-color: #28a745;
        }
        .score-good { 
            background: linear-gradient(135deg, #fff3cd, #ffeaa7); 
            border-color: #ffc107;
        }
        .score-poor { 
            background: linear-gradient(135deg, #f8d7da, #f5c6cb); 
            border-color: #dc3545;
        }
        
        /* Enhanced issue styling */
        .issue-list { list-style: none; padding: 0; }
        .issue-item { 
            padding: 15px; 
            margin: 10px 0; 
            border-radius: 8px; 
            border-left: 4px solid;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
        }
        .issue-item:hover {
            transform: translateX(5px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.15);
        }
        .issue-critical { 
            background: linear-gradient(90deg, #f8d7da, #f5c6cb); 
            border-left-color: #dc3545; 
        }
        .issue-error { 
            background: linear-gradient(90deg, #f8d7da, #f5c6cb); 
            border-left-color: #dc3545; 
        }
        .issue-warning { 
            background: linear-gradient(90deg, #fff3cd, #ffeaa7); 
            border-left-color: #ffc107; 
        }
        .issue-info { 
            background: linear-gradient(90deg, #d1ecf1, #bee5eb); 
            border-left-color: #17a2b8; 
        }
        
        /* Enhanced grid and cards */
        .stats-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); 
            gap: 20px; 
            margin: 20px 0; 
        }
        .stat-card { 
            background: linear-gradient(135deg, #ffffff, #f8f9fa); 
            padding: 20px; 
            border-radius: 12px; 
            border: 1px solid #dee2e6;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            transition: all 0.3s ease;
        }
        .stat-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.12);
        }
        
        /* Enhanced styling elements */
        .timestamp { color: rgba(255,255,255,0.9); font-size: 1.1em; font-weight: 300; }
        table { 
            width: 100%; 
            border-collapse: collapse; 
            margin: 20px 0; 
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        th, td { padding: 15px; text-align: left; }
        th { 
            background: linear-gradient(90deg, #007acc, #0056b3); 
            color: white;
            font-weight: 600;
        }
        td { border-bottom: 1px solid #dee2e6; }
        
        /* Premium recommendations section */
        .recommendations { 
            background: linear-gradient(135deg, #e7f3ff, #d4edda); 
            padding: 25px; 
            border-radius: 12px; 
            border-left: 6px solid #007acc;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
        }
        
        /* Responsive design improvements */
        @media (max-width: 768px) {
            body { padding: 10px; }
            .container { padding: 20px; }
            .header { margin: -20px -20px 20px -20px; padding: 30px 20px; }
            .header h1 { font-size: 2em; }
            .health-score { grid-template-columns: 1fr; }
            .stats-grid { grid-template-columns: 1fr; }
        }
        
        /* Loading animation and modern touches */
        .fade-in {
            animation: fadeIn 0.8s ease-in;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        /* Status badges with better visual indicators */
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .status-excellent { background: #28a745; color: white; }
        .status-good { background: #ffc107; color: #333; }
        .status-poor { background: #dc3545; color: white; }
        
        /* Executive summary styling */
        .executive-summary {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            padding: 30px;
            border-radius: 12px;
            margin-bottom: 30px;
            box-shadow: 0 15px 35px rgba(0,0,0,0.2);
        }
        .executive-summary h3 {
            margin: 0 0 15px 0;
            font-size: 1.5em;
        }
    </style>
    <script>
        function toggleSection(element) {
            const content = element.nextElementSibling;
            const section = element.parentElement;
            
            if (section.classList.contains('collapsible')) {
                section.classList.remove('collapsible');
                content.style.display = 'block';
                element.innerHTML = element.innerHTML.replace('▶', '▼');
            } else {
                section.classList.add('collapsible');
                content.style.display = 'none';
                element.innerHTML = element.innerHTML.replace('▼', '▶');
            }
        }
        
        // Add fade-in animation on load
        document.addEventListener('DOMContentLoaded', function() {
            document.querySelector('.container').classList.add('fade-in');
        });
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 RocketChat Support Dump Analysis Report</h1>
            <p class="timestamp">Generated on $(Get-Date -Format "MMMM dd, yyyy 'at' HH:mm:ss")</p>
            <p><strong>Analysis Path:</strong> $($Results.DumpPath)</p>
        </div>
        
        <!-- Executive Summary -->
        <div class="executive-summary">
            <h3>📋 Executive Summary</h3>
            <p><strong>System Health:</strong> <span class="status-badge $(if ($healthScore.OverallScore -ge 90) { 'status-excellent' } elseif ($healthScore.OverallScore -ge 70) { 'status-good' } else { 'status-poor' })">$($healthScore.OverallScore)% $(if ($healthScore.OverallScore -ge 90) { 'EXCELLENT' } elseif ($healthScore.OverallScore -ge 70) { 'GOOD' } else { 'NEEDS ATTENTION' })</span></p>
            <p><strong>Total Issues Found:</strong> $($healthScore.Issues.Critical + $healthScore.Issues.Error + $healthScore.Issues.Warning + $healthScore.Issues.Info) 
            $(if ($healthScore.Issues.Critical -gt 0) { "⚠️ Including $($healthScore.Issues.Critical) critical issue(s)" })
            </p>
            <p><strong>Recommended Action:</strong> $(if ($healthScore.OverallScore -lt 50) { "🚨 Immediate attention required for system stability" } elseif ($healthScore.OverallScore -lt 70) { "⚠️ Address identified issues to improve performance" } elseif ($healthScore.OverallScore -lt 90) { "✅ System is stable with minor improvements recommended" } else { "🎉 System is performing optimally" })</p>
        </div>
        
        <div class="section">
            <h2 onclick="toggleSection(this)">📊 Health Overview ▼</h2>
            <div class="section-content">
                <div class="health-score">
                    <div class="score-card $(if ($healthScore.OverallScore -ge 90) { 'score-excellent' } elseif ($healthScore.OverallScore -ge 70) { 'score-good' } else { 'score-poor' })">
                        <h3>🎯 Overall Health</h3>
                        <div style="font-size: 3em; font-weight: bold; margin: 10px 0;">$($healthScore.OverallScore)%</div>
                        <span class="status-badge $(if ($healthScore.OverallScore -ge 90) { 'status-excellent' } elseif ($healthScore.OverallScore -ge 70) { 'status-good' } else { 'status-poor' })">
                            $(if ($healthScore.OverallScore -ge 90) { 'EXCELLENT' } elseif ($healthScore.OverallScore -ge 70) { 'GOOD' } else { 'CRITICAL' })
                        </span>
                    </div>
                    <div class="score-card">
                        <h3>📊 Total Issues</h3>
                        <div style="font-size: 3em; font-weight: bold; margin: 10px 0; color: $(if ($Results.Summary.TotalIssues -eq 0) { '#28a745' } elseif ($healthScore.Issues.Critical -gt 0) { '#dc3545' } else { '#ffc107' });">$($Results.Summary.TotalIssues)</div>
                        <small style="color: #6c757d;">All severity levels</small>
                    </div>
                    <div class="score-card $(if ($healthScore.Issues.Critical -eq 0) { 'score-excellent' } else { 'score-poor' })">
                        <h3>🚨 Critical Issues</h3>
                        <div style="font-size: 3em; font-weight: bold; margin: 10px 0; color: #dc3545;">$($healthScore.Issues.Critical)</div>
                        <small style="color: #6c757d;">Requiring immediate attention</small>
                    </div>
                </div>
                
                <div class="stats-grid">
                    <div class="stat-card">
                        <h4>🏥 Component Health</h4>
                        <ul style="list-style: none; padding: 0; margin: 0;">
$(foreach ($component in $healthScore.ComponentScores.GetEnumerator()) {
    $color = if ($component.Value -ge 90) { "#28a745" } elseif ($component.Value -ge 70) { "#ffc107" } else { "#dc3545" }
    $icon = if ($component.Value -ge 90) { "🟢" } elseif ($component.Value -ge 70) { "🟡" } else { "🔴" }
    "                            <li style='color: $color; margin: 8px 0; display: flex; justify-content: space-between; align-items: center;'>
                                <span>$icon $($component.Key)</span> 
                                <span style='font-weight: bold; font-size: 1.1em;'>$($component.Value)%</span>
                            </li>"
})
                        </ul>
                    </div>
                    <div class="stat-card">
                        <h4>📈 Issues by Severity</h4>
                        <ul style="list-style: none; padding: 0; margin: 0;">
                            <li style="color: #dc3545; margin: 8px 0; display: flex; justify-content: space-between; align-items: center;">
                                <span>🚨 Critical</span> 
                                <span style="font-weight: bold; font-size: 1.2em;">$($healthScore.Issues.Critical)</span>
                            </li>
                            <li style="color: #dc3545; margin: 8px 0; display: flex; justify-content: space-between; align-items: center;">
                                <span>❌ Error</span> 
                                <span style="font-weight: bold; font-size: 1.2em;">$($healthScore.Issues.Error)</span>
                            </li>
                            <li style="color: #ffc107; margin: 8px 0; display: flex; justify-content: space-between; align-items: center;">
                                <span>⚠️ Warning</span> 
                                <span style="font-weight: bold; font-size: 1.2em;">$($healthScore.Issues.Warning)</span>
                            </li>
                            <li style="color: #17a2b8; margin: 8px 0; display: flex; justify-content: space-between; align-items: center;">
                                <span>ℹ️ Info</span> 
                                <span style="font-weight: bold; font-size: 1.2em;">$($healthScore.Issues.Info)</span>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
"@

    # Add log analysis section
    if ($Results.LogAnalysis -and $Results.LogAnalysis.Issues) {
        $html += @"
        <div class="section">
            <h2 onclick="toggleSection(this)">📝 Log Analysis ▼</h2>
            <div class="section-content">
                <div class="stats-grid">
                    <div class="stat-card">
                        <h4>📊 Log Summary</h4>
                        <p><strong>Total Entries:</strong> $($Results.LogAnalysis.Summary.TotalEntries)</p>
                        <p><strong>Errors:</strong> <span style="color: #dc3545; font-weight: bold;">$($Results.LogAnalysis.Summary.ErrorCount)</span></p>
                        <p><strong>Warnings:</strong> <span style="color: #ffc107; font-weight: bold;">$($Results.LogAnalysis.Summary.WarningCount)</span></p>
                        <p><strong>Info:</strong> <span style="color: #17a2b8; font-weight: bold;">$($Results.LogAnalysis.Summary.InfoCount)</span></p>
                    </div>
$(if ($Results.LogAnalysis.TimeRange.Start) {
"                <div class='stat-card'>
                    <h4>🕒 Time Range</h4>
                    <p><strong>From:</strong> $($Results.LogAnalysis.TimeRange.Start)</p>
                    <p><strong>To:</strong> $($Results.LogAnalysis.TimeRange.End)</p>
                    <p><strong>Duration:</strong> $(((Get-Date $Results.LogAnalysis.TimeRange.End) - (Get-Date $Results.LogAnalysis.TimeRange.Start)).TotalHours.ToString('F1')) hours</p>
                </div>"
})
                </div>
                
                <h3>🚨 Issues Found (Top 20)</h3>
                <ul class="issue-list">
$(foreach ($issue in ($Results.LogAnalysis.Issues | Select-Object -First 20)) {
    $cssClass = "issue-" + $issue.Severity.ToLower()
    $icon = switch ($issue.Severity) {
        "Critical" { "🚨" }
        "Error" { "❌" }
        "Warning" { "⚠️" }
        default { "ℹ️" }
    }
    "                <li class='issue-item $cssClass'>
                    <div style='display: flex; align-items: center; gap: 10px;'>
                        <span style='font-size: 1.2em;'>$icon</span>
                        <div>
                            <strong>[$($issue.Severity)]</strong> $($issue.Message)
                            $(if ($issue.Timestamp) { "<br><small style='color: #6c757d;'>🕒 $($issue.Timestamp)</small>" })
                        </div>
                    </div>
                </li>"
})
                </ul>
            </div>
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
            <h2 onclick="toggleSection(this)">💡 Recommendations & Action Items ▼</h2>
            <div class="section-content">
                <div class="recommendations">
                    <h3>🎯 Priority Actions</h3>
                    <ul style="margin: 0; padding-left: 20px;">
$(foreach ($rec in $healthScore.Recommendations) {
    "                        <li style='margin: 10px 0; padding: 5px 0;'>💡 $rec</li>"
})
$(if ($securityAnalysis.Recommendations) {
    foreach ($rec in $securityAnalysis.Recommendations) {
        "                        <li style='margin: 10px 0; padding: 5px 0;'>🔒 $rec</li>"
    }
})
                    </ul>
                    
                    <h3 style="margin-top: 25px;">📋 Next Steps</h3>
                    <div style="background: rgba(255,255,255,0.8); padding: 15px; border-radius: 8px; margin-top: 10px;">
                        <ol style="margin: 0; padding-left: 20px;">
$(if ($healthScore.Issues.Critical -gt 0) {
    "                            <li style='margin: 8px 0; color: #dc3545;'><strong>URGENT:</strong> Address all critical issues immediately</li>"
})
$(if ($healthScore.Issues.Error -gt 0) {
    "                            <li style='margin: 8px 0; color: #dc3545;'>Resolve error-level issues within 24 hours</li>"
})
$(if ($healthScore.Issues.Warning -gt 0) {
    "                            <li style='margin: 8px 0; color: #ffc107;'>Plan to address warning issues in next maintenance window</li>"
})
                            <li style="margin: 8px 0; color: #17a2b8;">Schedule regular health checks and monitoring</li>
                            <li style="margin: 8px 0; color: #28a745;">Document any changes made for future reference</li>
                        </ol>
                    </div>
                    
                    $(if ($healthScore.OverallScore -lt 70) {
                        "<div style='background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 8px; margin-top: 15px;'>
                            <h4 style='margin: 0 0 10px 0; color: #856404;'>⚠️ System Health Alert</h4>
                            <p style='margin: 0; color: #856404;'>Your RocketChat instance requires attention. Consider engaging support team for assistance with critical issues.</p>
                        </div>"
                    })
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2 onclick="toggleSection(this)">📋 Analysis Summary & Technical Details ▶</h2>
            <div class="section-content" style="display: none;">
                <div class="stats-grid">
                    <div class="stat-card">
                        <h4>📊 Analysis Coverage</h4>
                        <p><strong>Components Analyzed:</strong> $(($Results.Keys | Where-Object { $_ -ne 'Summary' -and $_ -ne 'Timestamp' -and $_ -ne 'DumpPath' }).Count)</p>
                        <p><strong>Data Sources:</strong> Logs, Settings, Statistics, Security</p>
                        <p><strong>Analysis Depth:</strong> Comprehensive</p>
                        <p><strong>Report Format:</strong> Executive HTML Report</p>
                    </div>
                    <div class="stat-card">
                        <h4>🛠️ Support Information</h4>
                        <p><strong>Tool Version:</strong> RocketChat Log Analyzer v1.2.0</p>
                        <p><strong>Analysis Date:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
                        <p><strong>Report Type:</strong> Professional Health Assessment</p>
                        <p><strong>Export Formats:</strong> HTML, JSON, CSV, Console</p>
                    </div>
                </div>
                
                <div style="background: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0; border-left: 4px solid #007acc;">
                    <h4 style="margin: 0 0 10px 0;">📞 Need Additional Support?</h4>
                    <p style="margin: 0;">For complex issues or detailed analysis, consider:</p>
                    <ul style="margin: 10px 0; padding-left: 20px;">
                        <li>Exporting detailed JSON report for technical teams</li>
                        <li>Scheduling a consultation with RocketChat support</li>
                        <li>Running additional diagnostics during maintenance windows</li>
                        <li>Setting up continuous monitoring and alerting</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
"@

    return $html
}

Export-ModuleMember -Function Write-ConsoleReport, New-JSONReport, New-CSVReport, New-HTMLReport
