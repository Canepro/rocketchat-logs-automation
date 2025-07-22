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
        Calculates an overall health score based on all analysis results.
    
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
    }
    
    # Count issues by severity
    foreach ($analysis in $AnalysisResults.Values) {
        if ($analysis -is [hashtable] -and $analysis.ContainsKey("Issues")) {
            foreach ($issue in $analysis.Issues) {
                switch ($issue.Severity) {
                    "Critical" { 
                        $healthScore.Issues.Critical++
                        $healthScore.OverallScore -= 25
                    }
                    "Error" { 
                        $healthScore.Issues.Error++
                        $healthScore.OverallScore -= 10
                    }
                    "Warning" { 
                        $healthScore.Issues.Warning++
                        $healthScore.OverallScore -= 5
                    }
                    "Info" { 
                        $healthScore.Issues.Info++
                        $healthScore.OverallScore -= 1
                    }
                }
            }
        }
    }
    
    # Calculate component scores
    if ($AnalysisResults.LogAnalysis -and $AnalysisResults.LogAnalysis.Issues) {
        $logIssues = $AnalysisResults.LogAnalysis.Issues.Count
        $healthScore.ComponentScores.Logs = [Math]::Max(100 - ($logIssues * 5), 0)
    }
    
    if ($AnalysisResults.SettingsAnalysis -and $AnalysisResults.SettingsAnalysis.Issues) {
        $settingsIssues = $AnalysisResults.SettingsAnalysis.Issues.Count
        $healthScore.ComponentScores.Settings = [Math]::Max(100 - ($settingsIssues * 10), 0)
    }
    
    if ($AnalysisResults.StatisticsAnalysis -and $AnalysisResults.StatisticsAnalysis.Issues) {
        $performanceIssues = $AnalysisResults.StatisticsAnalysis.Issues.Count
        $healthScore.ComponentScores.Performance = [Math]::Max(100 - ($performanceIssues * 15), 0)
    }
    
    # Ensure overall score doesn't go below 0
    $healthScore.OverallScore = [Math]::Max($healthScore.OverallScore, 0)
    
    # Generate recommendations based on score
    if ($healthScore.OverallScore -lt 50) {
        $healthScore.Recommendations += "Critical: Immediate attention required for multiple components"
    } elseif ($healthScore.OverallScore -lt 70) {
        $healthScore.Recommendations += "Warning: Several issues need to be addressed"
    } elseif ($healthScore.OverallScore -lt 90) {
        $healthScore.Recommendations += "Good: Minor improvements recommended"
    } else {
        $healthScore.Recommendations += "Excellent: System is running optimally"
    }
    
    return $healthScore
}

Export-ModuleMember -Function Get-ErrorPatterns, Get-TrendAnalysis, Get-PerformanceInsights, Get-SecurityAnalysis, Get-HealthScore
