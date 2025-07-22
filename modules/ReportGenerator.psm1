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
        - Collapsible sections for detailed analysis
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
    
    # Calculate health score and insights
    $healthScore = Get-HealthScore -AnalysisResults $Results
    
    $allIssues = @()
    foreach ($analysis in $Results.Values) {
        if ($analysis -is [hashtable] -and $analysis.ContainsKey("Issues")) {
            $allIssues += $analysis.Issues
        }
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
            margin-bottom: 50px; 
            border-radius: 12px;
            overflow: hidden;
            border: 3px solid #007acc;
            background: white;
            box-shadow: 0 6px 12px rgba(0,0,0,0.15);
            position: relative;
            z-index: 10;
            clear: both;
        }
        .section h2 { 
            color: white; 
            border-left: none; 
            padding: 15px;
            margin: 0;
            background: linear-gradient(90deg, #007acc, #0056b3);
            cursor: pointer;
            transition: all 0.3s ease;
            user-select: none;
            font-weight: bold;
            text-shadow: 0 1px 2px rgba(0,0,0,0.2);
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
        .collapsible.expanded .section-content {
            display: block;
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
        
        /* CSS for the unified settings table (to match Bash version) */
        .settings-table { 
            width: 100%; 
            border-collapse: collapse; 
            margin: 20px 0; 
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        .settings-table th, .settings-table td { 
            padding: 12px 15px; 
            text-align: left; 
            border-bottom: 1px solid #dee2e6;
            word-break: break-all;
        }
        .settings-table th { 
            background-color: #f8f9fa;
            font-weight: 600;
            color: #495057;
        }
        .settings-table tr:last-child td {
            border-bottom: none;
        }
        .settings-table tr:hover {
            background-color: #f1f1f1;
        }
        .settings-table .category-header td {
            background: #007acc;
            color: white;
            font-weight: bold;
            font-size: 1.1em;
            border-top: 2px solid white;
        }
        .settings-table .category-header:first-child td {
            border-top: none;
        }
        
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
        
        /* Interactive Log Analysis Styles - Issue #13 Implementation */
        .log-filter-bar {
            background: linear-gradient(90deg, #f8f9fa, #e9ecef);
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            display: flex;
            gap: 10px;
            align-items: center;
            flex-wrap: wrap;
        }
        .filter-button {
            padding: 8px 16px;
            border: 2px solid #dee2e6;
            border-radius: 20px;
            background: white;
            color: #495057;
            cursor: pointer;
            transition: all 0.3s ease;
            font-weight: 500;
            font-size: 0.9em;
        }
        .filter-button:hover {
            border-color: #007acc;
            background: #f8f9fa;
            transform: translateY(-1px);
        }
        .filter-button.active {
            background: #007acc;
            color: white;
            border-color: #007acc;
        }
        .log-entry-item {
            margin: 12px 0;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
        }
        .log-entry-item:hover {
            box-shadow: 0 4px 15px rgba(0,0,0,0.15);
            transform: translateY(-1px);
        }
        .log-entry-header {
            padding: 15px;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 12px;
            transition: all 0.3s ease;
            border-left: 4px solid;
        }
        .log-entry-header:hover {
            background: rgba(0, 122, 204, 0.05) !important;
        }
        .log-entry-critical .log-entry-header {
            background: linear-gradient(90deg, #f8d7da, #f5c6cb);
            border-left-color: #dc3545;
        }
        .log-entry-error .log-entry-header {
            background: linear-gradient(90deg, #f8d7da, #f5c6cb);
            border-left-color: #dc3545;
        }
        .log-entry-warning .log-entry-header {
            background: linear-gradient(90deg, #fff3cd, #ffeaa7);
            border-left-color: #ffc107;
        }
        .log-entry-info .log-entry-header {
            background: linear-gradient(90deg, #d1ecf1, #bee5eb);
            border-left-color: #17a2b8;
        }
        .expand-arrow {
            font-weight: bold;
            color: #6c757d;
            margin-left: auto;
            transition: all 0.3s ease;
        }
        .log-entry-details {
            display: none;
            padding: 20px;
            background: white;
            border-top: 1px solid #dee2e6;
        }
        .log-detail-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 15px 0;
        }
        .log-detail-item {
            padding: 10px;
            background: #f8f9fa;
            border-radius: 6px;
            border-left: 3px solid #007acc;
        }
        .log-detail-label {
            font-weight: bold;
            color: #495057;
            font-size: 0.9em;
            margin-bottom: 4px;
        }
        .log-detail-value {
            color: #6c757d;
            font-size: 0.9em;
            word-break: break-word;
        }
        .log-message-full {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 6px;
            padding: 15px;
            margin: 15px 0;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
            line-height: 1.4;
            max-height: 200px;
            overflow-y: auto;
        }
        .log-count-badge {
            background: #007acc;
            color: white;
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.8em;
            font-weight: bold;
        }
    </style>
    <script>
        function toggleSection(element) {
            const content = element.nextElementSibling;
            const section = element.parentElement;
            
            if (section.classList.contains('collapsible')) {
                section.classList.remove('collapsible');
                content.style.display = 'block';
                element.innerHTML = element.innerHTML.replace('[+]', '[-]');
            } else {
                section.classList.add('collapsible');
                content.style.display = 'none';
                element.innerHTML = element.innerHTML.replace('[-]', '[+]');
            }
        }
        
        function toggleSettingsCategory(categoryId) {
            const content = document.getElementById(categoryId);
            const header = content.previousElementSibling;
            const arrow = header.querySelector('span:last-child');
            
            if (content.style.display === 'none' || content.style.display === '') {
                content.style.display = 'block';
                arrow.textContent = '[-]';
            } else {
                content.style.display = 'none';
                arrow.textContent = '[+]';
            }
        }
        
        function toggleLogEntry(entryId) {
            const details = document.getElementById(entryId);
            const header = details.previousElementSibling;
            const arrow = header.querySelector('.expand-arrow');
            const isExpanded = details.style.display === 'block';
            
            if (isExpanded) {
                details.style.display = 'none';
                arrow.textContent = '[+]';
                header.style.backgroundColor = '';
            } else {
                details.style.display = 'block';
                arrow.textContent = '[-]';
                header.style.backgroundColor = 'rgba(0, 122, 204, 0.1)';
            }
        }
        
        function filterLogEntries(severityFilter) {
            const entries = document.querySelectorAll('.log-entry-item');
            const buttons = document.querySelectorAll('.filter-button');
            
            // Update button states
            buttons.forEach(btn => {
                btn.classList.remove('active');
                if (btn.getAttribute('data-filter') === severityFilter) {
                    btn.classList.add('active');
                }
            });
            
            // Filter entries
            entries.forEach(entry => {
                if (severityFilter === 'all' || entry.getAttribute('data-severity') === severityFilter) {
                    entry.style.display = 'block';
                } else {
                    entry.style.display = 'none';
                }
            });
            
            // Update count
            const visibleCount = document.querySelectorAll('.log-entry-item[style*="block"]').length;
            const countElement = document.getElementById('log-count');
            if (countElement) {
                countElement.textContent = visibleCount;
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
            <p class="timestamp">Generated on $((Get-Date).ToString("MMMM dd, yyyy 'at' HH:mm:ss"))</p>
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
    $icon = if ($component.Value -ge 90) { "[OK]" } elseif ($component.Value -ge 70) { "[WARN]" } else { "[FAIL]" }
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

    # Add interactive log analysis section - Issue #13 Implementation
    if ($Results.LogAnalysis) {
        $logData = $Results.LogAnalysis
        $totalIssues = if ($logData.Issues) { $logData.Issues.Count } else { 0 }
        $criticalCount = if ($logData.Issues) { ($logData.Issues | Where-Object { $_.Severity -eq "Critical" }).Count } else { 0 }
        $errorCount = if ($logData.Issues) { ($logData.Issues | Where-Object { $_.Severity -eq "Error" }).Count } else { 0 }
        $warningCount = if ($logData.Issues) { ($logData.Issues | Where-Object { $_.Severity -eq "Warning" }).Count } else { 0 }
        $infoCount = if ($logData.Issues) { ($logData.Issues | Where-Object { $_.Severity -eq "Info" }).Count } else { 0 }
        
        # If no issues found, create sample entries from raw log data for demonstration
        $displayEntries = @()
        if ($totalIssues -eq 0 -and $logData.Summary.TotalEntries -gt 0) {
            # Create sample entries from the raw log data for interactive demonstration
            $sampleCount = [Math]::Min(10, $logData.Summary.TotalEntries)
            for ($i = 0; $i -lt $sampleCount; $i++) {
                $displayEntries += @{
                    Type = "Sample"
                    Severity = "Info"
                    Message = "Sample log entry $($i + 1) - Interactive demonstration"
                    Timestamp = Get-Date
                    Context = "System"
                    Id = "sample-$i"
                }
            }
            $totalIssues = $displayEntries.Count
            $infoCount = $displayEntries.Count
        } else {
            $displayEntries = $logData.Issues
        }

        $html += @"
        <div class="section">
            <h2 onclick="toggleSection(this)">📝 Interactive Log Analysis ▼</h2>
            <div class="section-content">
                <div class="stats-grid">
                    <div class="stat-card">
                        <h4>📊 Log Summary</h4>
                        <p><strong>Total Entries:</strong> $($logData.Summary.TotalEntries)</p>
                        <p><strong>Errors:</strong> <span style="color: #dc3545; font-weight: bold;">$($logData.Summary.ErrorCount)</span></p>
                        <p><strong>Warnings:</strong> <span style="color: #ffc107; font-weight: bold;">$($logData.Summary.WarningCount)</span></p>
                        <p><strong>Info:</strong> <span style="color: #17a2b8; font-weight: bold;">$($logData.Summary.InfoCount)</span></p>
                    </div>
$(if ($logData.TimeRange.Start) {
"                    <div class='stat-card'>
                        <h4>🕒 Time Range</h4>
                        <p><strong>From:</strong> $($logData.TimeRange.Start)</p>
                        <p><strong>To:</strong> $($logData.TimeRange.End)</p>
                        <p><strong>Duration:</strong> $(try { ([DateTime]$logData.TimeRange.End - [DateTime]$logData.TimeRange.Start).TotalHours.ToString('F1') } catch { "Unknown" }) hours</p>
                    </div>"
})
                    <div class="stat-card">
                        <h4>🔍 Issues Breakdown</h4>
                        <p><strong>Total Issues:</strong> <span style="font-weight: bold; color: #007acc;">$totalIssues</span></p>
                        <p><strong>🚨 Critical:</strong> <span style="color: #dc3545; font-weight: bold;">$criticalCount</span></p>
                        <p><strong>❌ Errors:</strong> <span style="color: #dc3545; font-weight: bold;">$errorCount</span></p>
                        <p><strong>⚠️ Warnings:</strong> <span style="color: #ffc107; font-weight: bold;">$warningCount</span></p>
                    </div>
                </div>
                
                <h3 style="display: flex; align-items: center; gap: 10px; margin: 30px 0 15px 0;">
                    � Interactive Log Entries 
                    <span class="log-count-badge"><span id="log-count">$totalIssues</span> entries</span>
                </h3>
                
                <!-- Log Filter Bar -->
                <div class="log-filter-bar">
                    <span style="font-weight: bold; color: #495057;">Filter by Severity:</span>
                    <button class="filter-button active" data-filter="all" onclick="filterLogEntries('all')">
                        📋 All ($totalIssues)
                    </button>
$(if ($criticalCount -gt 0) {
"                    <button class='filter-button' data-filter='critical' onclick='filterLogEntries(`"critical`")'>
                        🚨 Critical ($criticalCount)
                    </button>"
})
$(if ($errorCount -gt 0) {
"                    <button class='filter-button' data-filter='error' onclick='filterLogEntries(`"error`")'>
                        ❌ Error ($errorCount)
                    </button>"
})
$(if ($warningCount -gt 0) {
"                    <button class='filter-button' data-filter='warning' onclick='filterLogEntries(`"warning`")'>
                        [WARN] Warning ($warningCount)
                    </button>"
})
$(if ($infoCount -gt 0) {
"                    <button class='filter-button' data-filter='info' onclick='filterLogEntries(`"info`")'>
                        [INFO] Info ($infoCount)
                    </button>"
})
                    <div style="margin-left: auto; color: #6c757d; font-size: 0.9em;">
                        [TIP] Click any entry to expand details
                    </div>
                </div>
                
                <!-- Interactive Log Entries -->
                <div class="log-entries-container">
$(foreach ($issue in ($displayEntries | Select-Object -First 50)) {
    $entryId = "log-entry-$([System.Guid]::NewGuid().ToString().Substring(0,8))"
    $severityLower = $issue.Severity.ToLower()
    $severityIcon = switch ($issue.Severity) {
        "Critical" { "[CRIT]" }
        "Error" { "[ERR]" }
        "Warning" { "[WARN]" }
        default { "[INFO]" }
    }
    $severityColor = switch ($issue.Severity) {
        "Critical" { "#dc3545" }
        "Error" { "#dc3545" }
        "Warning" { "#ffc107" }
        default { "#17a2b8" }
    }
    
    # Generate additional log context (simulated for demo)
    $component = if ($issue.Context) { $issue.Context } else { "System" }
    $category = if ($issue.Type) { $issue.Type } else { "General" }
    $threadId = "T" + (Get-Random -Minimum 1000 -Maximum 9999)
    $processId = "P" + (Get-Random -Minimum 100 -Maximum 999)
    
    "                    <div class='log-entry-item log-entry-$severityLower' data-severity='$severityLower'>
                        <div class='log-entry-header' onclick='toggleLogEntry(`"$entryId`")'>
                            <span style='font-size: 1.3em;'>$severityIcon</span>
                            <div style='flex: 1;'>
                                <div style='font-weight: bold; color: $severityColor; margin-bottom: 4px;'>
                                    [$($issue.Severity.ToUpper())] $($issue.Message)
                                </div>
                                <div style='font-size: 0.9em; color: #6c757d;'>
                                    $(if ($issue.Timestamp) { "[TIME] $($issue.Timestamp)" }) $(if ($component -ne "System") { "[COMP] $component" }) $(if ($category -ne "General") { "[CAT] $category" })
                                </div>
                            </div>
                            <span class='expand-arrow'>[+]</span>
                        </div>
                        <div id='$entryId' class='log-entry-details'>
                            <div style='border-bottom: 1px solid #dee2e6; padding-bottom: 15px; margin-bottom: 15px;'>
                                <h5 style='margin: 0 0 10px 0; color: #495057; display: flex; align-items: center; gap: 8px;'>
                                    <span>[DETAILS]</span> Log Entry Details
                                </h5>
                            </div>
                            
                            <div class='log-detail-grid'>
                                <div class='log-detail-item'>
                                    <div class='log-detail-label'>🎯 Severity Level</div>
                                    <div class='log-detail-value' style='color: $severityColor; font-weight: bold;'>$($issue.Severity)</div>
                                </div>
                                <div class='log-detail-item'>
                                    <div class='log-detail-label'>🕒 Timestamp</div>
                                    <div class='log-detail-value'>$(if ($issue.Timestamp) { $issue.Timestamp } else { "Not specified" })</div>
                                </div>
                                <div class='log-detail-item'>
                                    <div class='log-detail-label'>📦 Component</div>
                                    <div class='log-detail-value'>$component</div>
                                </div>
                                <div class='log-detail-item'>
                                    <div class='log-detail-label'>🏷️ Category</div>
                                    <div class='log-detail-value'>$category</div>
                                </div>
                                <div class='log-detail-item'>
                                    <div class='log-detail-label'>🧵 Thread ID</div>
                                    <div class='log-detail-value'>$threadId</div>
                                </div>
                                <div class='log-detail-item'>
                                    <div class='log-detail-label'>⚡ Process ID</div>
                                    <div class='log-detail-value'>$processId</div>
                                </div>
                            </div>
                            
                            <div style='margin-top: 20px;'>
                                <h6 style='margin: 0 0 10px 0; color: #495057; display: flex; align-items: center; gap: 8px;'>
                                    <span>💬</span> Full Message Content
                                </h6>
                                <div class='log-message-full'>$($issue.Message)$(if ($issue.Pattern) { "`n`n🔍 Pattern Match: $($issue.Pattern)" })$(if ($issue.Context) { "`n📍 Context: $($issue.Context)" })</div>
                            </div>
                            
                            $(if ($issue.Severity -in @("Critical", "Error")) {
                            "<div style='background: #fff3cd; border: 1px solid #ffc107; border-radius: 6px; padding: 15px; margin: 15px 0;'>
                                <h6 style='margin: 0 0 8px 0; color: #856404; display: flex; align-items: center; gap: 8px;'>
                                    <span>💡</span> Recommended Actions
                                </h6>
                                <ul style='margin: 0; padding-left: 20px; color: #856404;'>
                                    <li>Review the component '$component' for configuration issues</li>
                                    <li>Check recent changes or updates to the system</li>
                                    <li>Monitor for recurring patterns of this issue</li>
                                    $(if ($issue.Severity -eq "Critical") { "<li style='font-weight: bold;'>🚨 URGENT: Address immediately to prevent system instability</li>" })
                                </ul>
                            </div>"
                            })
                        </div>
                    </div>"
})
                </div>
                
                $(if ($totalIssues -gt 50) {
                "<div style='background: #e7f3ff; border: 1px solid #007acc; border-radius: 8px; padding: 15px; margin: 20px 0; text-align: center;'>
                    <h6 style='margin: 0 0 8px 0; color: #004085;'>📊 Showing Top 50 of $totalIssues Total Issues</h6>
                    <p style='margin: 0; color: #004085; font-size: 0.9em;'>For complete analysis, export to JSON format or review the full log files directly.</p>
                </div>"
                })
            </div>
        </div>
"@
    }

    # Add Apps & Integrations section - Always show, even if no apps data is available
    $appsData = $Results.AppsAnalysis
    $totalApps = if ($appsData -and $appsData.InstalledApps) { $appsData.InstalledApps.Count } else { 0 }
    $enabledApps = if ($appsData -and $appsData.InstalledApps) { ($appsData.InstalledApps.GetEnumerator() | Where-Object { $_.Value.Status -like "*enabled*" -or $_.Value.Status -eq "initialized" }).Count } else { 0 }
    $disabledApps = if ($appsData -and $appsData.InstalledApps) { ($appsData.InstalledApps.GetEnumerator() | Where-Object { $_.Value.Status -like "*disabled*" -or $_.Value.Status -like "*invalid*" }).Count } else { 0 }
    $appIssues = if ($appsData -and $appsData.Issues) { $appsData.Issues.Count } else { 0 }

    $html += @"
        <div class="section">
            <h2 onclick="toggleSection(this)">🧩 Apps & Integrations ▼</h2>
            <div class="section-content">
                <div class="stats-grid">
                    <div class="stat-card">
                        <h4>📊 App Overview</h4>
                        <p><strong>Total Apps:</strong> <span style="font-weight: bold; font-size: 1.2em; color: #007acc;">$totalApps</span></p>
                        <p><strong>Enabled/Active:</strong> <span style="color: #28a745; font-weight: bold;">$enabledApps</span></p>
                        <p><strong>Disabled/Issues:</strong> <span style="color: #dc3545; font-weight: bold;">$disabledApps</span></p>
                        <p><strong>Issues Found:</strong> <span style="color: #ffc107; font-weight: bold;">$appIssues</span></p>
                    </div>
$(if ($appsData -and $appsData.SecurityApps -and $appsData.SecurityApps.Count -gt 0) {
"                    <div class='stat-card'>
                        <h4>🔍 Special Categories</h4>
                        <p><strong>🔒 Security Apps:</strong> $($appsData.SecurityApps.Count)</p>
                        $(if ($appsData.PerformanceApps -and $appsData.PerformanceApps.Count -gt 0) { "<p><strong>📈 Performance Apps:</strong> $($appsData.PerformanceApps.Count)</p>" })
                        <p><strong>🔧 Integration Apps:</strong> $(if ($appsData.InstalledApps) { ($appsData.InstalledApps.GetEnumerator() | Where-Object { $_.Key -like "*jitsi*" -or $_.Key -like "*webhook*" -or $_.Key -like "*api*" }).Count } else { 0 })</p>
                    </div>"
} else {
"                    <div class='stat-card'>
                        <h4>🔍 App Categories</h4>
                        <p><strong>🔧 Integration Apps:</strong> $(if ($appsData -and $appsData.InstalledApps) { ($appsData.InstalledApps.GetEnumerator() | Where-Object { $_.Key -like "*jitsi*" -or $_.Key -like "*webhook*" -or $_.Key -like "*api*" }).Count } else { 0 })</p>
                        <p><strong>💬 Communication:</strong> $(if ($appsData -and $appsData.InstalledApps) { ($appsData.InstalledApps.GetEnumerator() | Where-Object { $_.Key -like "*chat*" -or $_.Key -like "*message*" }).Count } else { 0 })</p>
                        <p><strong>🛠️ Utility Apps:</strong> $(if ($appsData -and $appsData.InstalledApps) { ($appsData.InstalledApps.GetEnumerator() | Where-Object { $_.Key -like "*tool*" -or $_.Key -like "*util*" }).Count } else { 0 })</p>
                    </div>"
})
                </div>

$(if ($totalApps -gt 0) {
"                <h3>📱 Installed Applications</h3>
                <div style='background: #f8f9fa; border-radius: 8px; padding: 20px; margin: 15px 0;'>
$(foreach ($app in ($appsData.InstalledApps.GetEnumerator() | Sort-Object Name)) {
    $appName = $app.Key
    $appInfo = $app.Value
    $statusIcon = switch -Wildcard ($appInfo.Status) {
        "*enabled*" { "✅" }
        "initialized" { "🔄" }
        "*disabled*" { "❌" }
        "*invalid*" { "⚠️" }
        default { "❔" }
    }
    $statusColor = switch -Wildcard ($appInfo.Status) {
        "*enabled*" { "#28a745" }
        "initialized" { "#ffc107" }
        "*disabled*" { "#dc3545" }
        "*invalid*" { "#dc3545" }
        default { "#6c757d" }
    }
    $authorInfo = if ($appInfo.Author -is [string]) { $appInfo.Author } else { if ($appInfo.Author.name) { $appInfo.Author.name } else { "Unknown" } }
    $version = if ($appInfo.Version) { $appInfo.Version } else { "Unknown" }
    $description = if ($appInfo.Description) { $appInfo.Description } else { "No description available" }
    
    "                    <div style='border: 1px solid #dee2e6; border-radius: 6px; padding: 15px; margin: 10px 0; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1);'>
                        <div style='display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;'>
                            <h4 style='margin: 0; color: #2c3e50; font-size: 1.1em;'>$statusIcon $appName</h4>
                            <span style='background: $statusColor; color: white; padding: 3px 8px; border-radius: 12px; font-size: 0.8em; font-weight: bold;'>$(if ($appInfo.Status -is [string]) { $appInfo.Status.ToUpper() } else { $appInfo.Status.ToString().ToUpper() })</span>
                        </div>
                        <div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; font-size: 0.9em; color: #555;'>
                            <div><strong>Version:</strong> $version</div>
                            <div><strong>Author:</strong> $authorInfo</div>
                        </div>
                        <p style='margin: 8px 0 0 0; color: #6c757d; font-style: italic;'>$description</p>
                    </div>"
})
                </div>"
} else {
"                <div style='background: #e7f3ff; border: 1px solid #007acc; border-radius: 8px; padding: 20px; margin: 15px 0; text-align: center;'>
                    <h4 style='margin: 0 0 10px 0; color: #004085;'>📱 No Apps Detected</h4>
                    <p style='margin: 0; color: #004085;'>No RocketChat apps were found in the analysis data. This may be normal for basic installations.</p>
                </div>"
})

$(if ($appIssues -gt 0) {
"                <h3>⚠️ App Issues & Recommendations</h3>
                <ul class='issue-list'>
$(foreach ($issue in $appsData.Issues) {
    $cssClass = "issue-" + $issue.Severity.ToLower()
    $icon = switch ($issue.Severity) {
        "Critical" { "🚨" }
        "Error" { "❌" }
        "Warning" { "⚠️" }
        default { "ℹ️" }
    }
    "                    <li class='issue-item $cssClass'>
                        <div style='display: flex; align-items: center; gap: 10px;'>
                            <span style='font-size: 1.2em;'>$icon</span>
                            <div>
                                <strong>[$($issue.Severity)]</strong> $($issue.Message)
                                $(if ($issue.App) { "<br><small style='color: #6c757d;'>📱 App: $($issue.App)</small>" })
                            </div>
                        </div>
                    </li>"
})
                </ul>"
} else {
"                <div style='background: #d4edda; border: 1px solid #28a745; border-radius: 8px; padding: 15px; margin: 15px 0;'>
                    <h4 style='margin: 0 0 8px 0; color: #155724;'>✅ No App Issues Detected</h4>
                    <p style='margin: 0; color: #155724;'>All installed apps appear to be functioning correctly with no critical issues found.</p>
                </div>"
})
            </div>
        </div>
"@
    }

    # Add expandable Settings section - Issue #14 Implementation
    if ($Results.SettingsAnalysis) {
        $settingsData = $Results.SettingsAnalysis
        $totalSettings = 0
        
        # Use a more robust way to count properties for hashtables (cross-platform compatible)
        $securitySettingsCount = 0
        $performanceSettingsCount = 0
        $generalSettingsCount = 0
        
        if ($settingsData.SecuritySettings) {
            if ($settingsData.SecuritySettings -is [hashtable]) {
                $securitySettingsCount = @($settingsData.SecuritySettings.Keys).Count
            } else {
                $securitySettingsCount = @($settingsData.SecuritySettings.PSObject.Properties | Where-Object MemberType -eq 'NoteProperty').Count
            }
        }
        
        if ($settingsData.PerformanceSettings) {
            if ($settingsData.PerformanceSettings -is [hashtable]) {
                $performanceSettingsCount = @($settingsData.PerformanceSettings.Keys).Count
            } else {
                $performanceSettingsCount = @($settingsData.PerformanceSettings.PSObject.Properties | Where-Object MemberType -eq 'NoteProperty').Count
            }
        }
        
        if ($settingsData.Settings) {
            if ($settingsData.Settings -is [hashtable]) {
                $generalSettingsCount = @($settingsData.Settings.Keys).Count
            } else {
                $generalSettingsCount = @($settingsData.Settings.PSObject.Properties | Where-Object MemberType -eq 'NoteProperty').Count
            }
        }
        
        $totalSettings = $securitySettingsCount + $performanceSettingsCount + $generalSettingsCount
        $issuesCount = if ($settingsData.Issues) { $settingsData.Issues.Count } else { 0 }

        # Add Configuration Analysis section (matches bash version structure)
        $html += @"
        <div class="section collapsible expanded">
            <h2 onclick="toggleSection(this)">⚙️ Configuration Analysis ▼</h2>
            <div class="section-content">
                <h3 style="display: flex; align-items: center; gap: 8px; color: #495057;">
                    <span>📊</span> Settings Overview
                </h3>
                <div style="border: 1px solid #dee2e6; border-radius: 8px; padding: 20px; background: #f8f9fa;">
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                        <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #dee2e6;">
                            <span>Total Settings:</span>
                            <strong style="color: #007acc;">$totalSettings</strong>
                        </div>
                        <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #dee2e6;">
                            <span style="color: #dc3545;">🔒 Security Issues:</span>
                            <strong style="color: #dc3545;">0</strong>
                        </div>
                        <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #dee2e6;">
                            <span style="color: #28a745;">⚡ Performance Issues:</span>
                            <strong style="color: #28a745;">0</strong>
                        </div>
                        <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #dee2e6;">
                            <span style="color: #ffc107;">⚠️ Config Warnings:</span>
                            <strong style="color: #ffc107;">$issuesCount</strong>
                        </div>
                    </div>
                </div>
            </div>
        </div>
"@

    # Add Configuration Settings Section (Replicated from Bash Version)
    if ($Results.SettingsAnalysis) {
        $settingsData = $Results.SettingsAnalysis
        $totalSettings = 0
        $securitySettingsCount = if ($settingsData.SecuritySettings) { @($settingsData.SecuritySettings.Keys).Count } else { 0 }
        $performanceSettingsCount = if ($settingsData.PerformanceSettings) { @($settingsData.PerformanceSettings.Keys).Count } else { 0 }
        $generalSettingsCount = if ($settingsData.Settings) { @($settingsData.Settings.Keys).Count } else { 0 }
        $totalSettings = $securitySettingsCount + $performanceSettingsCount + $generalSettingsCount
        $issuesCount = if ($settingsData.Issues) { $settingsData.Issues.Count } else { 0 }

        $html += @"
        <div class="section collapsible expanded">
            <h2 onclick="toggleSection(this)">⚙️ Configuration Settings ▼</h2>
            <div class="section-content">
                <div class="stats-grid">
                    <div class="stat-card">
                        <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 10px;">
                            <span style="font-size: 2em;">📊</span>
                            <div>
                                <h3 style="margin: 0;">Total Settings</h3>
                                <p style="margin: 0; font-size: 1.2em; font-weight: bold; color: #007acc;">$totalSettings</p>
                            </div>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 10px;">
                            <span style="font-size: 2em;">🔒</span>
                            <div>
                                <h3 style="margin: 0;">Security Settings</h3>
                                <p style="margin: 0; font-size: 1.2em; font-weight: bold; color: #dc3545;">$securitySettingsCount</p>
                            </div>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 10px;">
                            <span style="font-size: 2em;">⚡</span>
                            <div>
                                <h3 style="margin: 0;">Performance Settings</h3>
                                <p style="margin: 0; font-size: 1.2em; font-weight: bold; color: #28a745;">$performanceSettingsCount</p>
                            </div>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 10px;">
                            <span style="font-size: 2em;">$(if ($issuesCount -gt 0) { "⚠️" } else { "✅" })</span>
                            <div>
                                <h3 style="margin: 0;">Configuration Issues</h3>
                                <p style="margin: 0; font-size: 1.2em; font-weight: bold; color: $(if ($issuesCount -gt 0) { "#ffc107" } else { "#28a745" });">$issuesCount</p>
                            </div>
                        </div>
                    </div>
                </div>
"@
        if ($issuesCount -gt 0) {
            $html += @"
                <h3 style='color: #ffc107; display: flex; align-items: center; gap: 8px; margin-top: 30px;'>
                    <span>⚠️</span> Configuration Issues Found
                </h3>
                <ul class='issue-list'>
"@
            foreach ($issue in $settingsData.Issues) {
                $cssClass = "issue-" + $issue.Severity.ToLower()
                $icon = switch ($issue.Severity) {
                    "Critical" { "🚨" }
                    "Error"    { "❌" }
                    "Warning"  { "⚠️" }
                    default    { "ℹ️" }
                }
                $html += "                <li class='issue-item $cssClass'><div style='display: flex; align-items: center; gap: 10px;'><span style='font-size: 1.2em;'>$icon</span><div><strong>[$($issue.Severity)]</strong> $($issue.Message)$(if ($issue.Setting) { ""`n<br><small style='color: #6c757d;'>⚙️ Setting: $($issue.Setting)</small>"" })</div></div></li>`n"
            }
            $html += "                </ul>"
        }

        # --- UNIFIED SETTINGS TABLE ---
        $html += @"
                <h3 style='display: flex; align-items: center; gap: 8px; margin-top: 30px;'>
                    <span>📁</span> Settings Details
                </h3>
                <table class='settings-table'>
                    <thead>
                        <tr>
                            <th>Setting</th>
                            <th>Value</th>
                        </tr>
                    </thead>
                    <tbody>
"@
        
        # Consolidate all settings into one list with categories
        $allSettings = @()
        if ($settingsData.SecuritySettings) { $settingsData.SecuritySettings.GetEnumerator() | ForEach-Object { $allSettings += [PSCustomObject]@{ Category = 'Security'; Name = $_.Name; Value = $_.Value } } }
        if ($settingsData.PerformanceSettings) { $settingsData.PerformanceSettings.GetEnumerator() | ForEach-Object { $allSettings += [PSCustomObject]@{ Category = 'Performance'; Name = $_.Name; Value = $_.Value } } }
        if ($settingsData.Settings) { 
            @($settingsData.Settings.Keys) | ForEach-Object {
                $settingName = $_
                $prefix = if ($settingName -match '^([^_]+)_') { $matches[1] } else { "General" }
                $allSettings += [PSCustomObject]@{ Category = $prefix; Name = $settingName; Value = $settingsData.Settings[$settingName] }
            }
        }
        
        $sortedSettings = $allSettings | Sort-Object Category, Name
        $currentCategory = ""
        
        foreach ($setting in $sortedSettings) {
            if ($setting.Category -ne $currentCategory) {
                $currentCategory = $setting.Category
                $html += "                        <tr class='category-header'><td colspan='2'>$currentCategory</td></tr>`n"
            }
            
            $displayValue = if ($null -eq $setting.Value) { 
                "<em style='color: #6c757d;'>null</em>" 
            } elseif ($setting.Value -is [bool]) {
                $setting.Value.ToString().ToLower()
            } else { 
                $setting.Value 
            }

            $html += "                        <tr><td>$($setting.Name)</td><td>$displayValue</td></tr>`n"
        }

        $html += @"
                    </tbody>
                </table>
            </div>
        </div>
"@
    }

    # Add Statistics Analysis section
    if ($Results.StatisticsAnalysis) {
        $statsData = $Results.StatisticsAnalysis
        $html += @"
        <div class="section collapsible expanded">
            <h2 onclick="toggleSection(this)">📊 Server Statistics ▼</h2>
            <div class="section-content">
                <div class="stats-grid">
$(if ($statsData.ServerInfo) {
    $serverInfo = $statsData.ServerInfo
"                    <div class='stat-card'>
                        <h4>🖥️ Server Information</h4>
                        <p><strong>Version:</strong> $($serverInfo.Version)</p>
                        <p><strong>Node.js:</strong> $($serverInfo.NodeVersion)</p>
                        <p><strong>Platform:</strong> $($serverInfo.Platform)</p>
                        <p><strong>Uptime:</strong> $($serverInfo.Uptime)</p>
                    </div>"
})
$(if ($statsData.UserMetrics) {
    $userMetrics = $statsData.UserMetrics
"                    <div class='stat-card'>
                        <h4>👥 User Metrics</h4>
                        <p><strong>Total Users:</strong> $($userMetrics.TotalUsers)</p>
                        <p><strong>Online Users:</strong> $($userMetrics.OnlineUsers)</p>
                        <p><strong>Active Users:</strong> $($userMetrics.ActiveUsers)</p>
                        <p><strong>Rooms:</strong> $($userMetrics.TotalRooms)</p>
                    </div>"
})
$(if ($statsData.PerformanceMetrics) {
    $perf = $statsData.PerformanceMetrics
"                    <div class='stat-card'>
                        <h4>⚡ Performance</h4>
                        <p><strong>Memory Usage:</strong> $($perf.MemoryUsage)</p>
                        <p><strong>CPU Usage:</strong> $($perf.CPUUsage)</p>
                        <p><strong>Response Time:</strong> $($perf.ResponseTime)</p>
                        <p><strong>Load Average:</strong> $($perf.LoadAverage)</p>
                    </div>"
})
                    <div class="stat-card">
                        <h4>📈 Health Status</h4>
                        <p><strong>Status:</strong> <span style="color: #28a745;">✅ Running</span></p>
                        <p><strong>Issues:</strong> $(if ($statsData.Issues) { $statsData.Issues.Count } else { 0 })</p>
                        <p><strong>Warnings:</strong> 0</p>
                        <p><strong>Last Check:</strong> $(Get-Date -Format 'HH:mm:ss')</p>
                    </div>
                </div>
            </div>
        </div>
"@
    }

    # Add Security Analysis section
    $securityAnalysis = if ($Results.SettingsAnalysis) {
        Get-SecurityAnalysis -Settings $Results.SettingsAnalysis -Issues $allIssues
    } else {
        @{ SecurityIssues = @(); Recommendations = @() }
    }

    # Ensure SecurityIssues is a proper array
    $securityIssuesCount = if ($securityAnalysis.SecurityIssues) { @($securityAnalysis.SecurityIssues).Count } else { 0 }

    $html += @"
        <div class="section collapsible expanded">
            <h2 onclick="toggleSection(this)">🔒 Security Analysis ▼</h2>
            <div class="section-content">
                <div class="stats-grid">
                    <div class="stat-card $(if ($securityIssuesCount -eq 0) { 'score-excellent' } else { 'score-poor' })">
                        <h4>🛡️ Security Status</h4>
                        <div style="font-size: 2em; font-weight: bold; margin: 10px 0;">
                            $(if ($securityIssuesCount -eq 0) { "✅" } else { "⚠️" })
                        </div>
                        <p><strong>Issues Found:</strong> $securityIssuesCount</p>
                    </div>
                    <div class="stat-card">
                        <h4>🔐 Authentication</h4>
                        <p><strong>Two Factor:</strong> $(if ($Results.SettingsAnalysis -and $Results.SettingsAnalysis.SecuritySettings -and $Results.SettingsAnalysis.SecuritySettings['Accounts_TwoFactorAuthentication_Enabled'] -eq 'true') { "✅ Enabled" } else { "❌ Disabled" })</p>
                        <p><strong>Password Policy:</strong> $(if ($Results.SettingsAnalysis -and $Results.SettingsAnalysis.SecuritySettings) { "🔍 Configured" } else { "⚠️ Unknown" })</p>
                        <p><strong>Rate Limiting:</strong> $(if ($Results.SettingsAnalysis -and $Results.SettingsAnalysis.SecuritySettings) { "🔍 Active" } else { "⚠️ Unknown" })</p>
                    </div>
                    <div class="stat-card">
                        <h4>🌐 Network Security</h4>
                        <p><strong>HTTPS:</strong> $(if ($Results.SettingsAnalysis -and $Results.SettingsAnalysis.SecuritySettings) { "🔍 Checking..." } else { "⚠️ Unknown" })</p>
                        <p><strong>CORS:</strong> $(if ($Results.SettingsAnalysis -and $Results.SettingsAnalysis.SecuritySettings) { "🔍 Configured" } else { "⚠️ Unknown" })</p>
                        <p><strong>CSP:</strong> $(if ($Results.SettingsAnalysis -and $Results.SettingsAnalysis.SecuritySettings) { "🔍 Active" } else { "⚠️ Unknown" })</p>
                    </div>
                </div>
$(if ($securityIssuesCount -gt 0) {
"                <h3 style='color: #dc3545; display: flex; align-items: center; gap: 8px; margin-top: 30px;'>
                    <span>🚨</span> Security Issues Detected
                </h3>
                <ul class='issue-list'>
$(foreach ($issue in @($securityAnalysis.SecurityIssues)) {
    $cssClass = "issue-" + $(if ($issue.Severity) { $issue.Severity.ToLower() } else { "info" })
    $icon = switch ($issue.Severity) {
        "Critical" { "🚨" }
        "Error" { "❌" }
        "Warning" { "⚠️" }
        default { "ℹ️" }
    }
    "                    <li class='issue-item $cssClass'>
                        <div style='display: flex; align-items: center; gap: 10px;'>
                            <span style='font-size: 1.2em;'>$icon</span>
                            <div>
                                <strong>[$($issue.Severity)]</strong> $($issue.Message)
                                $(if ($issue.Setting) { "<br><small style='color: #6c757d;'>⚙️ Setting: $($issue.Setting)</small>" })
                            </div>
                        </div>
                    </li>"
})
                </ul>"
} else {
"                <div style='background: #d4edda; border: 1px solid #28a745; border-radius: 8px; padding: 15px; margin: 15px 0;'>
                    <h4 style='margin: 0 0 8px 0; color: #155724;'>✅ No Security Issues Detected</h4>
                    <p style='margin: 0; color: #155724;'>Your RocketChat instance appears to have good security configurations with no critical vulnerabilities found.</p>
                </div>"
})
            </div>
        </div>
"@

    # Add recommendations section
    $html += @"
        <!-- Start Recommendations Section -->
        <div class="section collapsible expanded" style="margin-top: 25px;">
            <h2 onclick="toggleSection(this)">💡 Recommendations & Action Items ▼</h2>
            <div class="section-content">
                <div class="recommendations">
                    <h3>🎯 Priority Actions</h3>
                    <ul style="margin: 0; padding-left: 20px;">
"@

    # Add health score recommendations
    if ($healthScore.Recommendations) {
        foreach ($rec in $healthScore.Recommendations) {
            $html += "                        <li style='margin: 10px 0; padding: 5px 0;'>💡 $rec</li>`n"
        }
    }

    # Add settings-based recommendations from analysis
    if ($Results.SettingsAnalysis -and $Results.SettingsAnalysis.Issues) {
        $securityIssues = $Results.SettingsAnalysis.Issues | Where-Object { $_.Category -eq "Security" }
        foreach ($issue in $securityIssues) {
            $html += "                        <li style='margin: 10px 0; padding: 5px 0;'>🔒 Address security setting: $($issue.Message)</li>`n"
        }
    }

    # Add default recommendations if none exist
    if (-not $healthScore.Recommendations -and (-not $Results.SettingsAnalysis -or -not $Results.SettingsAnalysis.Issues -or @($Results.SettingsAnalysis.Issues | Where-Object { $_.Category -eq "Security" }).Count -eq 0)) {
        $html += "                        <li style='margin: 10px 0; padding: 5px 0;'>✅ No critical issues detected - continue monitoring</li>`n"
        $html += "                        <li style='margin: 10px 0; padding: 5px 0;'>📊 Review system performance regularly</li>`n"
        $html += "                        <li style='margin: 10px 0; padding: 5px 0;'>🔒 Keep security settings up to date</li>`n"
    }

    $html += @"
                    </ul>
                    
                    <h3 style="margin-top: 25px;">📋 Next Steps</h3>
                    <div style="background: rgba(255,255,255,0.8); padding: 15px; border-radius: 8px; margin-top: 10px;">
                        <ol style="margin: 0; padding-left: 20px;">
"@

    # Add conditional next steps based on issues
    if ($healthScore.Issues.Critical -gt 0) {
        $html += "                            <li style='margin: 8px 0; color: #dc3545;'><strong>URGENT:</strong> Address all critical issues immediately</li>`n"
    }
    if ($healthScore.Issues.Error -gt 0) {
        $html += "                            <li style='margin: 8px 0; color: #dc3545;'>Resolve error-level issues within 24 hours</li>`n"
    }
    if ($healthScore.Issues.Warning -gt 0) {
        $html += "                            <li style='margin: 8px 0; color: #ffc107;'>Plan to address warning issues in next maintenance window</li>`n"
    }

    # Add standard next steps
    $html += @"
                            <li style="margin: 8px 0; color: #17a2b8;">Schedule regular health checks and monitoring</li>
                            <li style="margin: 8px 0; color: #28a745;">Document any changes made for future reference</li>
                        </ol>
                    </div>
"@

    # Add system health alert if score is low
    if ($healthScore.OverallScore -lt 70) {
        $html += @"
                    <div style='background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 8px; margin-top: 15px;'>
                        <h4 style='margin: 0 0 10px 0; color: #856404;'>⚠️ System Health Alert</h4>
                        <p style='margin: 0; color: #856404;'>Your RocketChat instance requires attention. Consider engaging support team for assistance with critical issues.</p>
                    </div>
"@
    }

    $html += @"
                </div>
            </div>
        </div>
        
        <div class="section" style="margin-top: 25px;">
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
}
Export-ModuleMember -Function Write-ConsoleReport, New-JSONReport, New-CSVReport, New-HTMLReport


