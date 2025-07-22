function New-SimpleHTMLReport {
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
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .header { text-align: center; color: #333; background: linear-gradient(135deg, #667eea, #764ba2); margin: -30px -30px 30px -30px; padding: 30px; border-radius: 10px 10px 0 0; color: white; }
        .header h1 { color: white; margin: 0; font-size: 2.5em; }
        .health-score { display: flex; justify-content: space-around; margin: 30px 0; }
        .health-item { text-align: center; padding: 20px; background: #f8f9fa; border-radius: 8px; }
        .health-number { font-size: 2.5em; font-weight: bold; color: #28a745; }
        .section { margin: 30px 0; padding: 20px; border: 1px solid #e9ecef; border-radius: 8px; }
        .section h2 { color: #495057; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
        .issue { margin: 10px 0; padding: 15px; border-left: 4px solid #ffc107; background: #fff3cd; border-radius: 0 4px 4px 0; }
        .issue.critical { border-left-color: #dc3545; background: #f8d7da; }
        .issue.error { border-left-color: #dc3545; background: #f8d7da; }
        .issue.warning { border-left-color: #ffc107; background: #fff3cd; }
        .issue.info { border-left-color: #17a2b8; background: #d1ecf1; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #e9ecef; color: #6c757d; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 RocketChat Analysis Report</h1>
            <p>Comprehensive Support Dump Analysis</p>
        </div>
        
        <div class="health-score">
            <div class="health-item">
                <div class="health-number">$($healthScore.OverallScore)%</div>
                <div>Overall Health</div>
            </div>
            <div class="health-item">
                <div class="health-number">$criticalCount</div>
                <div>Critical Issues</div>
            </div>
            <div class="health-item">
                <div class="health-number">$errorCount</div>
                <div>Errors</div>
            </div>
            <div class="health-item">
                <div class="health-number">$warningCount</div>
                <div>Warnings</div>
            </div>
        </div>
"@

    # Add log analysis section if available
    if ($Results.ContainsKey("LogAnalysis") -and $Results.LogAnalysis.ContainsKey("Summary")) {
        $logSummary = $Results.LogAnalysis.Summary
        $htmlContent += @"
        
        <div class="section">
            <h2>📝 Log Analysis</h2>
            <table>
                <tr><th>Metric</th><th>Value</th></tr>
                <tr><td>Total Entries</td><td>$($logSummary.TotalEntries)</td></tr>
                <tr><td>Errors</td><td>$($logSummary.ErrorCount)</td></tr>
                <tr><td>Warnings</td><td>$($logSummary.WarningCount)</td></tr>
                <tr><td>Info Messages</td><td>$($logSummary.InfoCount)</td></tr>
            </table>
        </div>
"@
    }

    # Add settings analysis section if available
    if ($Results.ContainsKey("SettingsAnalysis") -and $Results.SettingsAnalysis.ContainsKey("Summary")) {
        $settingsSummary = $Results.SettingsAnalysis.Summary
        $htmlContent += @"
        
        <div class="section">
            <h2>⚙️ Settings Analysis</h2>
            <table>
                <tr><th>Metric</th><th>Value</th></tr>
                <tr><td>Total Settings</td><td>$($settingsSummary.TotalSettings)</td></tr>
                <tr><td>Security Issues</td><td>$($settingsSummary.SecurityIssues)</td></tr>
                <tr><td>Performance Issues</td><td>$($settingsSummary.PerformanceIssues)</td></tr>
            </table>
        </div>
"@
    }

    # Add statistics section if available
    if ($Results.ContainsKey("StatisticsAnalysis") -and $Results.StatisticsAnalysis.ContainsKey("Summary")) {
        $statsSummary = $Results.StatisticsAnalysis.Summary
        $htmlContent += @"
        
        <div class="section">
            <h2>📊 Server Statistics</h2>
            <table>
                <tr><th>Metric</th><th>Value</th></tr>
                <tr><td>RocketChat Version</td><td>$($statsSummary.Version)</td></tr>
                <tr><td>Total Users</td><td>$($statsSummary.TotalUsers)</td></tr>
                <tr><td>Online Users</td><td>$($statsSummary.OnlineUsers)</td></tr>
                <tr><td>Total Messages</td><td>$($statsSummary.TotalMessages)</td></tr>
            </table>
        </div>
"@
    }

    # Add top issues section
    if ($allIssues.Count -gt 0) {
        $htmlContent += @"
        
        <div class="section">
            <h2>🔍 Top Issues</h2>
"@
        
        foreach ($issue in ($allIssues | Select-Object -First 10)) {
            $severityClass = $issue.Severity.ToLower()
            $htmlContent += @"
            <div class="issue $severityClass">
                <strong>[$($issue.Severity.ToUpper())]</strong> $($issue.Message -replace '"', '&quot;' -replace '<', '&lt;' -replace '>', '&gt;')
            </div>
"@
        }
        
        $htmlContent += "        </div>"
    }

    # Add recommendations
    if ($healthScore.Recommendations -and $healthScore.Recommendations.Count -gt 0) {
        $htmlContent += @"
        
        <div class="section">
            <h2>💡 Recommendations</h2>
"@
        foreach ($rec in $healthScore.Recommendations) {
            $htmlContent += "            <div class='issue info'>$($rec -replace '"', '&quot;' -replace '<', '&lt;' -replace '>', '&gt;')</div>`n"
        }
        $htmlContent += "        </div>"
    }

    # Add footer
    $htmlContent += @"
        
        <div class="footer">
            <p><strong>Tool Version:</strong> RocketChat Support Dump Analyzer v1.4.8 (PowerShell)</p>
            <p><strong>Generated:</strong> $timestamp</p>
            <p>Report generated by RocketChat Log Automation Tool</p>
        </div>
    </div>
</body>
</html>
"@

    return $htmlContent
}

# Test the function
try {
    # Import modules
    $ModulesPath = Join-Path $PSScriptRoot "modules"
    Import-Module (Join-Path $ModulesPath "RocketChatLogParser.psm1") -Force
    Import-Module (Join-Path $ModulesPath "RocketChatAnalyzer.psm1") -Force  
    Import-Module (Join-Path $ModulesPath "ReportGenerator.psm1") -Force

    # Create test data
    $TestResults = @{
        LogAnalysis = @{
            Summary = @{
                TotalEntries = 1000
                ErrorCount = 5
                WarningCount = 10
                InfoCount = 985
            }
            Issues = @(
                @{ Severity = "Warning"; Message = "Test warning message"; Timestamp = "2025-07-22 15:00:00" }
                @{ Severity = "Error"; Message = "Test error message"; Timestamp = "2025-07-22 15:01:00" }
            )
        }
        SettingsAnalysis = @{
            Summary = @{
                TotalSettings = 1021
                SecurityIssues = 2
                PerformanceIssues = 1
            }
            Issues = @()
        }
        StatisticsAnalysis = @{
            Summary = @{
                Version = "7.8.0"
                TotalUsers = 22
                OnlineUsers = 5
                TotalMessages = 15000
            }
        }
    }

    Write-Host "Creating working HTML report..." -ForegroundColor Yellow
    $report = New-SimpleHTMLReport -Results $TestResults
    
    if ($report -and $report.Length -gt 0) {
        $report | Out-File -FilePath "working-report.html" -Encoding UTF8
        Write-Host "SUCCESS: Working HTML report created! Size: $($report.Length) bytes" -ForegroundColor Green
        Write-Host "File saved as: working-report.html" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Report generation failed" -ForegroundColor Red
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
