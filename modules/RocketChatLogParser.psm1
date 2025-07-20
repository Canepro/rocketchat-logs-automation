<#
.SYNOPSIS
    RocketChat Log Parser Module - Functions for parsing and analyzing RocketChat log files.

.DESCRIPTION
    This module provides functions to parse various RocketChat log formats and extract
    meaningful information for analysis.
#>

function Invoke-LogAnalysis {
    <#
    .SYNOPSIS
        Analyzes RocketChat log files for errors, warnings, and patterns.
    
    .PARAMETER LogFile
        Path to the RocketChat log file (JSON format)
    
    .PARAMETER Config
        Configuration object containing analysis rules
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile,
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    $results = @{
        Issues = @()
        Patterns = @{}
        Summary = @{
            TotalEntries = 0
            ErrorCount = 0
            WarningCount = 0
            InfoCount = 0
        }
        TimeRange = @{
            Start = $null
            End = $null
        }
    }
    
    try {
        Write-Verbose "Reading log file: $LogFile"
        
        if (-not (Test-Path $LogFile)) {
            throw "Log file not found: $LogFile"
        }
        
        $logContent = Get-Content $LogFile -Raw | ConvertFrom-Json
        
        if ($logContent -is [array]) {
            $logEntries = $logContent
        } elseif ($logContent.logs) {
            $logEntries = $logContent.logs
        } else {
            $logEntries = @($logContent)
        }
        
        $results.Summary.TotalEntries = $logEntries.Count
        Write-Verbose "Processing $($logEntries.Count) log entries"
        
        foreach ($entry in $logEntries) {
            # Parse timestamp
            if ($entry.timestamp -or $entry.ts -or $entry.time) {
                $timestamp = $entry.timestamp ?? $entry.ts ?? $entry.time
                try {
                    $parsedTime = [DateTime]::Parse($timestamp)
                    if (-not $results.TimeRange.Start -or $parsedTime -lt $results.TimeRange.Start) {
                        $results.TimeRange.Start = $parsedTime
                    }
                    if (-not $results.TimeRange.End -or $parsedTime -gt $results.TimeRange.End) {
                        $results.TimeRange.End = $parsedTime
                    }
                } catch {
                    Write-Verbose "Could not parse timestamp: $timestamp"
                }
            }
            
            # Determine log level
            $level = $entry.level ?? $entry.severity ?? "info"
            $message = $entry.message ?? $entry.msg ?? $entry.text ?? ""
            
            # Count by level
            switch ($level.ToLower()) {
                "error" { $results.Summary.ErrorCount++ }
                "warn" { $results.Summary.WarningCount++ }
                "warning" { $results.Summary.WarningCount++ }
                default { $results.Summary.InfoCount++ }
            }
            
            # Check for error patterns
            foreach ($pattern in $Config.LogPatterns.Error) {
                if ($message -match $pattern) {
                    $results.Issues += @{
                        Type = "Error"
                        Severity = "Error"
                        Message = $message
                        Pattern = $pattern
                        Timestamp = $timestamp
                        Context = $entry
                    }
                    
                    # Track pattern frequency
                    if (-not $results.Patterns[$pattern]) {
                        $results.Patterns[$pattern] = 0
                    }
                    $results.Patterns[$pattern]++
                }
            }
            
            # Check for warning patterns
            foreach ($pattern in $Config.LogPatterns.Warning) {
                if ($message -match $pattern) {
                    $results.Issues += @{
                        Type = "Warning"
                        Severity = "Warning"
                        Message = $message
                        Pattern = $pattern
                        Timestamp = $timestamp
                        Context = $entry
                    }
                }
            }
            
            # Check for security patterns
            foreach ($pattern in $Config.LogPatterns.Security) {
                if ($message -match $pattern) {
                    $results.Issues += @{
                        Type = "Security"
                        Severity = "Warning"
                        Message = $message
                        Pattern = $pattern
                        Timestamp = $timestamp
                        Context = $entry
                    }
                }
            }
        }
        
        Write-Verbose "Log analysis complete. Found $($results.Issues.Count) issues"
        
    } catch {
        Write-Error "Error analyzing log file: $($_.Exception.Message)"
        $results.Issues += @{
            Type = "Analysis Error"
            Severity = "Critical"
            Message = "Failed to analyze log file: $($_.Exception.Message)"
            Timestamp = Get-Date
        }
    }
    
    return $results
}

function Invoke-SettingsAnalysis {
    <#
    .SYNOPSIS
        Analyzes RocketChat settings for configuration issues.
    
    .PARAMETER SettingsFile
        Path to the RocketChat settings file (JSON format)
    
    .PARAMETER Config
        Configuration object containing analysis rules
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$SettingsFile,
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    $results = @{
        Issues = @()
        Settings = @{}
        SecuritySettings = @{}
        PerformanceSettings = @{}
    }
    
    try {
        Write-Verbose "Reading settings file: $SettingsFile"
        
        if (-not (Test-Path $SettingsFile)) {
            throw "Settings file not found: $SettingsFile"
        }
        
        $settingsContent = Get-Content $SettingsFile -Raw | ConvertFrom-Json
        
        if ($settingsContent -is [array]) {
            $settings = $settingsContent
        } else {
            $settings = @($settingsContent)
        }
        
        foreach ($setting in $settings) {
            $key = $setting._id ?? $setting.key ?? $setting.name
            $value = $setting.value ?? $setting.setting
            
            if ($key) {
                $results.Settings[$key] = $value
                
                # Check security-related settings
                if ($key -match "password|auth|security|token|secret") {
                    $results.SecuritySettings[$key] = $value
                    
                    # Check for weak security configurations
                    if ($key -match "password" -and $value -eq $false) {
                        $results.Issues += @{
                            Type = "Security"
                            Severity = "Warning"
                            Message = "Password requirement disabled: $key"
                            Setting = $key
                            Value = $value
                        }
                    }
                }
                
                # Check performance-related settings
                if ($key -match "limit|timeout|max|cache|size") {
                    $results.PerformanceSettings[$key] = $value
                    
                    # Check for performance issues
                    if ($key -match "timeout" -and [int]$value -gt 30000) {
                        $results.Issues += @{
                            Type = "Performance"
                            Severity = "Warning"
                            Message = "High timeout value detected: $key = $value"
                            Setting = $key
                            Value = $value
                        }
                    }
                }
            }
        }
        
        Write-Verbose "Settings analysis complete. Found $($results.Issues.Count) issues"
        
    } catch {
        Write-Error "Error analyzing settings file: $($_.Exception.Message)"
        $results.Issues += @{
            Type = "Analysis Error"
            Severity = "Critical"
            Message = "Failed to analyze settings file: $($_.Exception.Message)"
        }
    }
    
    return $results
}

function Invoke-StatisticsAnalysis {
    <#
    .SYNOPSIS
        Analyzes RocketChat server statistics for performance and health issues.
    
    .PARAMETER StatisticsFile
        Path to the RocketChat statistics file (JSON format)
    
    .PARAMETER Config
        Configuration object containing analysis rules
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$StatisticsFile,
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    $results = @{
        Issues = @()
        ServerInfo = @{}
        PerformanceMetrics = @{}
        ResourceUsage = @{}
    }
    
    try {
        Write-Verbose "Reading statistics file: $StatisticsFile"
        
        if (-not (Test-Path $StatisticsFile)) {
            throw "Statistics file not found: $StatisticsFile"
        }
        
        $statsContent = Get-Content $StatisticsFile -Raw | ConvertFrom-Json
        
        # Extract server information
        if ($statsContent.version) {
            $results.ServerInfo.Version = $statsContent.version
        }
        if ($statsContent.uniqueId) {
            $results.ServerInfo.UniqueId = $statsContent.uniqueId
        }
        if ($statsContent.installedAt) {
            $results.ServerInfo.InstalledAt = $statsContent.installedAt
        }
        
        # Extract performance metrics
        if ($statsContent.statistics) {
            $stats = $statsContent.statistics
            
            # Memory usage
            if ($stats.process) {
                $results.PerformanceMetrics.Memory = @{
                    Used = $stats.process.memory?.rss
                    Heap = $stats.process.memory?.heapUsed
                    External = $stats.process.memory?.external
                }
                
                # Check memory thresholds
                if ($stats.process.memory?.rss -gt 1000000000) { # 1GB
                    $results.Issues += @{
                        Type = "Performance"
                        Severity = "Warning"
                        Message = "High memory usage detected: $($stats.process.memory.rss / 1000000)MB"
                        Metric = "Memory"
                        Value = $stats.process.memory.rss
                    }
                }
            }
            
            # User statistics
            if ($stats.totalUsers) {
                $results.PerformanceMetrics.Users = @{
                    Total = $stats.totalUsers
                    Online = $stats.onlineUsers
                    Away = $stats.awayUsers
                    Offline = $stats.offlineUsers
                }
            }
            
            # Message statistics
            if ($stats.totalMessages) {
                $results.PerformanceMetrics.Messages = @{
                    Total = $stats.totalMessages
                    Channels = $stats.totalChannels
                    PrivateGroups = $stats.totalPrivateGroups
                    DirectMessages = $stats.totalDirect
                }
            }
        }
        
        Write-Verbose "Statistics analysis complete. Found $($results.Issues.Count) issues"
        
    } catch {
        Write-Error "Error analyzing statistics file: $($_.Exception.Message)"
        $results.Issues += @{
            Type = "Analysis Error"
            Severity = "Critical"
            Message = "Failed to analyze statistics file: $($_.Exception.Message)"
        }
    }
    
    return $results
}

function Invoke-OmnichannelAnalysis {
    <#
    .SYNOPSIS
        Analyzes RocketChat Omnichannel configuration.
    
    .PARAMETER OmnichannelFile
        Path to the RocketChat Omnichannel file (JSON format)
    
    .PARAMETER Config
        Configuration object containing analysis rules
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$OmnichannelFile,
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    $results = @{
        Issues = @()
        Configuration = @{}
        Integrations = @{}
    }
    
    try {
        Write-Verbose "Reading Omnichannel file: $OmnichannelFile"
        
        if (-not (Test-Path $OmnichannelFile)) {
            Write-Verbose "Omnichannel file not found: $OmnichannelFile"
            return $results
        }
        
        $omnichannelContent = Get-Content $OmnichannelFile -Raw | ConvertFrom-Json
        
        # Analyze Omnichannel configuration
        # Add specific analysis logic based on Omnichannel structure
        
        Write-Verbose "Omnichannel analysis complete. Found $($results.Issues.Count) issues"
        
    } catch {
        Write-Error "Error analyzing Omnichannel file: $($_.Exception.Message)"
        $results.Issues += @{
            Type = "Analysis Error"
            Severity = "Critical"
            Message = "Failed to analyze Omnichannel file: $($_.Exception.Message)"
        }
    }
    
    return $results
}

function Invoke-AppsAnalysis {
    <#
    .SYNOPSIS
        Analyzes RocketChat installed apps and integrations.
    
    .PARAMETER AppsFile
        Path to the RocketChat apps file (JSON format)
    
    .PARAMETER Config
        Configuration object containing analysis rules
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppsFile,
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    $results = @{
        Issues = @()
        InstalledApps = @{}
        SecurityApps = @{}
        PerformanceApps = @{}
    }
    
    try {
        Write-Verbose "Reading apps file: $AppsFile"
        
        if (-not (Test-Path $AppsFile)) {
            Write-Verbose "Apps file not found: $AppsFile"
            return $results
        }
        
        $appsContent = Get-Content $AppsFile -Raw | ConvertFrom-Json
        
        # Analyze installed apps
        # Add specific analysis logic based on apps structure
        
        Write-Verbose "Apps analysis complete. Found $($results.Issues.Count) issues"
        
    } catch {
        Write-Error "Error analyzing apps file: $($_.Exception.Message)"
        $results.Issues += @{
            Type = "Analysis Error"
            Severity = "Critical"
            Message = "Failed to analyze apps file: $($_.Exception.Message)"
        }
    }
    
    return $results
}

Export-ModuleMember -Function Invoke-LogAnalysis, Invoke-SettingsAnalysis, Invoke-StatisticsAnalysis, Invoke-OmnichannelAnalysis, Invoke-AppsAnalysis
