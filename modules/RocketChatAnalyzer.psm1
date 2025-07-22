<#
.SYNOPSIS
    RocketChat Analyzer Module - Advanced analysis functions for RocketChat data.

.DESCRIPTION
    This module provides advanced analysis capabilities including pattern detection,
    trend analysis, and intelligent issue correlation.
#>

function Get-ErrorPatterns {
    <#
    .SYNOPSIS
        Identifies common error patterns in log data.
    
    .PARAMETER Issues
        Array of issues to analyze for patterns
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Issues
    )
    
    $patterns = @{}
    
    foreach ($issue in $Issues) {
        if ($issue.Pattern) {
            if (-not $patterns[$issue.Pattern]) {
                $patterns[$issue.Pattern] = @{
                    Count = 0
                    Severity = $issue.Severity
                    Messages = @()
                    FirstSeen = $issue.Timestamp
                    LastSeen = $issue.Timestamp
                }
            }
            
            $patterns[$issue.Pattern].Count++
            $patterns[$issue.Pattern].Messages += $issue.Message
            
            if ($issue.Timestamp) {
                try {
                    $timestamp = [DateTime]::Parse($issue.Timestamp)
                    if ($timestamp -lt [DateTime]::Parse($patterns[$issue.Pattern].FirstSeen)) {
                        $patterns[$issue.Pattern].FirstSeen = $issue.Timestamp
                    }
                    if ($timestamp -gt [DateTime]::Parse($patterns[$issue.Pattern].LastSeen)) {
                        $patterns[$issue.Pattern].LastSeen = $issue.Timestamp
                    }
                } catch {
                    # Invalid timestamp format, skip
                }
            }
        }
    }
    
    return $patterns
}

function Get-TrendAnalysis {
    <#
    .SYNOPSIS
        Analyzes trends in log data over time.
    
    .PARAMETER Issues
        Array of issues with timestamps to analyze
    
    .PARAMETER TimeWindow
        Time window for trend analysis (hours)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Issues,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeWindow = 24
    )
    
    $trends = @{
        ErrorTrend = @{}
        WarningTrend = @{}
        HourlyDistribution = @{}
        DailyDistribution = @{}
    }
    
    foreach ($issue in $Issues) {
        if ($issue.Timestamp) {
            try {
                $timestamp = [DateTime]::Parse($issue.Timestamp)
                $hour = $timestamp.Hour
                $day = $timestamp.DayOfWeek
                
                # Hourly distribution
                if (-not $trends.HourlyDistribution[$hour]) {
                    $trends.HourlyDistribution[$hour] = 0
                }
                $trends.HourlyDistribution[$hour]++
                
                # Daily distribution
                if (-not $trends.DailyDistribution[$day]) {
                    $trends.DailyDistribution[$day] = 0
                }
                $trends.DailyDistribution[$day]++
                
                # Severity trends
                switch ($issue.Severity) {
                    "Error" {
                        $key = $timestamp.ToString("yyyy-MM-dd HH:00")
                        if (-not $trends.ErrorTrend[$key]) {
                            $trends.ErrorTrend[$key] = 0
                        }
                        $trends.ErrorTrend[$key]++
                    }
                    "Warning" {
                        $key = $timestamp.ToString("yyyy-MM-dd HH:00")
                        if (-not $trends.WarningTrend[$key]) {
                            $trends.WarningTrend[$key] = 0
                        }
                        $trends.WarningTrend[$key]++
                    }
                }
            } catch {
                # Invalid timestamp, skip
            }
        }
    }
    
    return $trends
}

function Get-PerformanceInsights {
    <#
    .SYNOPSIS
        Analyzes performance metrics and provides insights.
    
    .PARAMETER Statistics
        Statistics data from RocketChat
    
    .PARAMETER Config
        Configuration with performance thresholds
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Statistics,
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    $insights = @{
        MemoryAnalysis = @{}
        UserLoadAnalysis = @{}
        MessageVolumeAnalysis = @{}
        Recommendations = @()
    }
    
    # Memory analysis
    if ($Statistics.PerformanceMetrics.Memory) {
        $memory = $Statistics.PerformanceMetrics.Memory
        $memoryMB = [math]::Round($memory.Used / 1024 / 1024, 2)
        
        $insights.MemoryAnalysis = @{
            UsedMB = $memoryMB
            HeapMB = [math]::Round($memory.Heap / 1024 / 1024, 2)
            Status = if ($memoryMB -gt 2048) { "High" } elseif ($memoryMB -gt 1024) { "Medium" } else { "Normal" }
        }
        
        if ($memoryMB -gt 2048) {
            $insights.Recommendations += "Consider increasing server memory or optimizing memory usage"
        }
    }
    
    # User load analysis
    if ($Statistics.PerformanceMetrics.Users) {
        $users = $Statistics.PerformanceMetrics.Users
        $onlineRatio = if ($users.Total -gt 0) { [math]::Round(($users.Online / $users.Total) * 100, 2) } else { 0 }
        
        $insights.UserLoadAnalysis = @{
            TotalUsers = $users.Total
            OnlineUsers = $users.Online
            OnlinePercentage = $onlineRatio
            LoadLevel = if ($users.Online -gt 1000) { "High" } elseif ($users.Online -gt 100) { "Medium" } else { "Low" }
        }
        
        if ($users.Online -gt 1000) {
            $insights.Recommendations += "High user load detected. Consider scaling infrastructure"
        }
    }
    
    # Message volume analysis
    if ($Statistics.PerformanceMetrics.Messages) {
        $messages = $Statistics.PerformanceMetrics.Messages
        
        $insights.MessageVolumeAnalysis = @{
            TotalMessages = $messages.Total
            Channels = $messages.Channels
            PrivateGroups = $messages.PrivateGroups
            DirectMessages = $messages.DirectMessages
            VolumeLevel = if ($messages.Total -gt 1000000) { "High" } elseif ($messages.Total -gt 100000) { "Medium" } else { "Low" }
        }
        
        if ($messages.Total -gt 1000000) {
            $insights.Recommendations += "High message volume. Consider implementing message retention policies"
        }
    }
    
    return $insights
}

function Get-SecurityAnalysis {
    <#
    .SYNOPSIS
        Analyzes security-related configuration and issues.
    
    .PARAMETER Settings
        Settings analysis results
    
    .PARAMETER Issues
        All identified issues (can be empty array)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Settings,
        
        [Parameter(Mandatory = $false)]
        [array]$Issues = @()
    )
    
    $security = @{
        SecurityScore = 100
        SecurityIssues = @()
        Recommendations = @()
        ConfigurationReview = @{}
    }
    
    # Analyze security settings
    if ($Settings -and $Settings.SecuritySettings) {
        foreach ($setting in $Settings.SecuritySettings.GetEnumerator()) {
            $key = $setting.Key
            $value = $setting.Value
            
            $security.ConfigurationReview[$key] = @{
                Value = $value
                Risk = "Low"
                Description = ""
            }
        
        # Check for common security misconfigurations
        switch -Regex ($key) {
            "Accounts_TwoFactorAuthentication_Enabled" {
                if ($value -eq $false) {
                    $issue = "Two-factor authentication is disabled"
                    if ($security.SecurityIssues -notcontains $issue) {
                        $security.SecurityScore -= 20
                        $security.SecurityIssues += $issue
                        $security.Recommendations += "Enable two-factor authentication for enhanced security"
                    }
                    $security.ConfigurationReview[$key].Risk = "High"
                }
            }
            "Accounts_RegistrationForm" {
                if ($value -eq "Public") {
                    $issue = "Public registration is enabled"
                    if ($security.SecurityIssues -notcontains $issue) {
                        $security.SecurityScore -= 10
                        $security.SecurityIssues += $issue
                        $security.Recommendations += "Consider restricting registration to invited users only"
                    }
                    $security.ConfigurationReview[$key].Risk = "Medium"
                }
            }
            "Accounts_PasswordReset" {
                if ($value -eq $false) {
                    $issue = "Password reset is disabled"
                    if ($security.SecurityIssues -notcontains $issue) {
                        $security.SecurityScore -= 5
                        $security.SecurityIssues += $issue
                    }
                    $security.ConfigurationReview[$key].Risk = "Medium"
                }
            }
            "FileUpload_Storage_Type" {
                if ($value -eq "FileSystem") {
                    $issue = "File uploads stored on filesystem"
                    if ($security.SecurityIssues -notcontains $issue) {
                        $security.SecurityScore -= 5
                        $security.SecurityIssues += $issue
                        $security.Recommendations += "Consider using cloud storage for file uploads"
                    }
                    $security.ConfigurationReview[$key].Risk = "Low"
                }
            }
        }
    }
    }
    
    # Analyze security-related issues from log analysis (avoid duplicates)
    $securityIssues = $Issues | Where-Object { $_.Type -eq "Security" }
    foreach ($issue in $securityIssues) {
        if ($security.SecurityIssues -notcontains $issue.Message) {
            $security.SecurityIssues += $issue.Message
            $security.SecurityScore -= 5
        }
    }
    
    # Ensure score doesn't go below 0
    $security.SecurityScore = [Math]::Max($security.SecurityScore, 0)
    
    return $security
}

function Get-HealthScore {
    <#
    .SYNOPSIS
        Calculates an overall health score based on all analysis results using nuanced scoring.
    
    .DESCRIPTION
        Implements the Project Phoenix v2.0.0 improved health scoring algorithm:
        - Critical issues: -20 points each
        - Error issues: -10 points each  
        - Warning issues: -2 points each
        - Info issues: -0.5 points each
        More accurately reflects system health compared to the overly punitive v1.x algorithm.
    
    .PARAMETER AnalysisResults
        Complete analysis results from all modules
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$AnalysisResults
    )
    
    $healthScore = @{
        OverallScore = 100
        ComponentScores = @{
            Logs = 100
            Settings = 100
            Performance = 100
            Security = 100
        }
        Issues = @{
            Critical = 0
            Error = 0
            Warning = 0
            Info = 0
        }
        Recommendations = @()
        DetailedBreakdown = @()
    }
    
    # Count issues by severity with more nuanced scoring
    $totalDeduction = 0
    foreach ($analysis in $AnalysisResults.Values) {
        if ($analysis -is [hashtable] -and $analysis.ContainsKey("Issues")) {
            foreach ($issue in $analysis.Issues) {
                switch ($issue.Severity) {
                    "Critical" { 
                        $healthScore.Issues.Critical++
                        $totalDeduction += 20
                        $healthScore.DetailedBreakdown += "Critical issue: $($issue.Message) (-20 pts)"
                    }
                    "Error" { 
                        $healthScore.Issues.Error++
                        $totalDeduction += 10
                        $healthScore.DetailedBreakdown += "Error: $($issue.Message) (-10 pts)"
                    }
                    "Warning" { 
                        $healthScore.Issues.Warning++
                        $totalDeduction += 2
                        $healthScore.DetailedBreakdown += "Warning: $($issue.Message) (-2 pts)"
                    }
                    "Info" { 
                        $healthScore.Issues.Info++
                        $totalDeduction += 0.5
                        $healthScore.DetailedBreakdown += "Info: $($issue.Message) (-0.5 pts)"
                    }
                }
            }
        }
    }
    
    # Apply total deduction
    $healthScore.OverallScore = [Math]::Max(100 - $totalDeduction, 0)
    
    # Calculate component-specific scores with nuanced logic
    if ($AnalysisResults.LogAnalysis) {
        $logCritical = ($AnalysisResults.LogAnalysis.Issues | Where-Object { $_.Severity -eq "Critical" }).Count
        $logErrors = ($AnalysisResults.LogAnalysis.Issues | Where-Object { $_.Severity -eq "Error" }).Count
        $logWarnings = ($AnalysisResults.LogAnalysis.Issues | Where-Object { $_.Severity -eq "Warning" }).Count
        
        $logDeduction = ($logCritical * 20) + ($logErrors * 10) + ($logWarnings * 2)
        $healthScore.ComponentScores.Logs = [Math]::Max(100 - $logDeduction, 0)
    }
    
    if ($AnalysisResults.SettingsAnalysis) {
        $settingsCritical = ($AnalysisResults.SettingsAnalysis.Issues | Where-Object { $_.Severity -eq "Critical" }).Count
        $settingsErrors = ($AnalysisResults.SettingsAnalysis.Issues | Where-Object { $_.Severity -eq "Error" }).Count
        $settingsWarnings = ($AnalysisResults.SettingsAnalysis.Issues | Where-Object { $_.Severity -eq "Warning" }).Count
        
        $settingsDeduction = ($settingsCritical * 20) + ($settingsErrors * 10) + ($settingsWarnings * 2)
        $healthScore.ComponentScores.Settings = [Math]::Max(100 - $settingsDeduction, 0)
    }
    
    if ($AnalysisResults.StatisticsAnalysis) {
        $perfCritical = ($AnalysisResults.StatisticsAnalysis.Issues | Where-Object { $_.Severity -eq "Critical" }).Count
        $perfErrors = ($AnalysisResults.StatisticsAnalysis.Issues | Where-Object { $_.Severity -eq "Error" }).Count
        $perfWarnings = ($AnalysisResults.StatisticsAnalysis.Issues | Where-Object { $_.Severity -eq "Warning" }).Count
        
        $perfDeduction = ($perfCritical * 20) + ($perfErrors * 10) + ($perfWarnings * 2)
        $healthScore.ComponentScores.Performance = [Math]::Max(100 - $perfDeduction, 0)
    }
    
    # Security scoring (aggregate from all security-related issues)
    $allSecurityIssues = @()
    foreach ($analysis in $AnalysisResults.Values) {
        if ($analysis -is [hashtable] -and $analysis.ContainsKey("Issues")) {
            $allSecurityIssues += $analysis.Issues | Where-Object { $_.Type -eq "Security" -or $_.Pattern -match "auth|login|security|unauthorized" }
        }
    }
    
    $secCritical = ($allSecurityIssues | Where-Object { $_.Severity -eq "Critical" }).Count
    $secErrors = ($allSecurityIssues | Where-Object { $_.Severity -eq "Error" }).Count  
    $secWarnings = ($allSecurityIssues | Where-Object { $_.Severity -eq "Warning" }).Count
    
    $secDeduction = ($secCritical * 20) + ($secErrors * 10) + ($secWarnings * 2)
    $healthScore.ComponentScores.Security = [Math]::Max(100 - $secDeduction, 0)
    
    # Generate intelligent recommendations based on issue patterns and scores
    if ($healthScore.Issues.Critical -gt 0) {
        $healthScore.Recommendations += "🚨 URGENT: $($healthScore.Issues.Critical) critical issue(s) require immediate attention"
    }
    
    if ($healthScore.Issues.Error -gt 5) {
        $healthScore.Recommendations += "⚠️ HIGH: Multiple error conditions detected ($($healthScore.Issues.Error) total) - investigate error patterns"
    }
    
    if ($healthScore.ComponentScores.Security -lt 80) {
        $healthScore.Recommendations += "🔒 SECURITY: Review authentication and authorization settings"
    }
    
    if ($healthScore.ComponentScores.Performance -lt 70) {
        $healthScore.Recommendations += "⚡ PERFORMANCE: System performance issues detected - check resource usage"
    }
    
    # Overall assessment recommendations
    if ($healthScore.OverallScore -ge 90) {
        $healthScore.Recommendations += "✅ EXCELLENT: System is operating optimally with minimal issues"
    } elseif ($healthScore.OverallScore -ge 75) {
        $healthScore.Recommendations += "✅ GOOD: System is stable with minor issues to address"
    } elseif ($healthScore.OverallScore -ge 50) {
        $healthScore.Recommendations += "⚠️ FAIR: System needs attention - multiple issues present"
    } elseif ($healthScore.OverallScore -ge 25) {
        $healthScore.Recommendations += "🚨 POOR: System has significant problems requiring urgent action"
    } else {
        $healthScore.Recommendations += "🚨 CRITICAL: System is severely compromised - immediate intervention required"
    }
    
    # Add contextual recommendations based on issue volume
    $totalIssues = $healthScore.Issues.Critical + $healthScore.Issues.Error + $healthScore.Issues.Warning + $healthScore.Issues.Info
    if ($totalIssues -gt 50) {
        $healthScore.Recommendations += "📊 ANALYSIS: High issue volume detected ($totalIssues total) - consider reviewing log retention and analysis patterns"
    }
    
    return $healthScore
}

Export-ModuleMember -Function Get-ErrorPatterns, Get-TrendAnalysis, Get-PerformanceInsights, Get-SecurityAnalysis, Get-HealthScore
