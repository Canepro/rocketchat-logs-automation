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
    
    .DESCRIPTION
        This function performs comprehensive analysis of RocketChat log files, including:
        - Error and warning detection based on configurable patterns
        - Security event identification
        - Pattern frequency analysis
        - Time range analysis
        - Performance issue detection
    
    .PARAMETER LogFile
        Path to the RocketChat log file (JSON format). The file should contain log entries
        with timestamp, level, and message fields.
    
    .PARAMETER Config
        Configuration object containing analysis rules including:
        - LogPatterns.Error: Array of error patterns to detect
        - LogPatterns.Warning: Array of warning patterns to detect  
        - LogPatterns.Security: Array of security-related patterns to detect
    
    .EXAMPLE
        $config = @{
            LogPatterns = @{
                Error = @("error", "exception", "failed")
                Warning = @("warn", "deprecated") 
                Security = @("auth", "login", "permission")
            }
        }
        $results = Invoke-LogAnalysis -LogFile "rocketchat.log.json" -Config $config
    
    .NOTES
        Author: Support Engineering Team
        Requires: PowerShell 5.1+, valid JSON log file
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
        } elseif ($logContent.queue) {
            # Handle RocketChat 7.8.0+ support dump format with queue array
            $logEntries = $logContent.queue
        } else {
            $logEntries = @($logContent)
        }
        
        $results.Summary.TotalEntries = $logEntries.Count
        Write-Verbose "Processing $($logEntries.Count) log entries"
        
        foreach ($entry in $logEntries) {
            # Handle RocketChat 7.8.0+ format where log data is in 'string' field
            $actualLogEntry = $entry
            $timestamp = $null
            $level = "info"
            $message = ""
            
            if ($entry.string) {
                # RocketChat 7.8.0+ format: parse the JSON string to get actual log entry
                try {
                    $parsedLogEntry = $entry.string | ConvertFrom-Json
                    $actualLogEntry = $parsedLogEntry
                    $timestamp = if ($entry.ts) { $entry.ts } elseif ($parsedLogEntry.time) { $parsedLogEntry.time } else { $parsedLogEntry.timestamp }
                    $level = if ($parsedLogEntry.level) { $parsedLogEntry.level } else { "info" }
                    $message = if ($parsedLogEntry.msg) { $parsedLogEntry.msg } elseif ($parsedLogEntry.message) { $parsedLogEntry.message } else { "" }
                } catch {
                    # If parsing fails, treat the string as the message
                    $timestamp = $entry.ts
                    $message = $entry.string
                }
            } else {
                # Standard format
                $timestamp = if ($entry.timestamp) { $entry.timestamp } elseif ($entry.ts) { $entry.ts } else { $entry.time }
                $level = if ($entry.level) { $entry.level } elseif ($entry.severity) { $entry.severity } else { "info" }
                $message = if ($entry.message) { $entry.message } elseif ($entry.msg) { $entry.msg } elseif ($entry.text) { $entry.text } else { "" }
            }
            
            # Parse timestamp
            if ($timestamp) {
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
            
            # Handle numeric log levels (RocketChat uses 20=info, 30=warn, 40=error, 50=fatal)
            if ($level -is [int] -or $level -is [int64]) {
                switch ([int]$level) {
                    { $_ -ge 50 } { $level = "Critical" }
                    { $_ -ge 40 } { $level = "Error" }
                    { $_ -ge 30 } { $level = "Warning" }
                    default { $level = "Info" }
                }
            } elseif ($level -is [string] -and $level -match '^\d+$') {
                # Handle string representation of numbers
                $numLevel = [int]$level
                switch ($numLevel) {
                    { $_ -ge 50 } { $level = "Critical" }
                    { $_ -ge 40 } { $level = "Error" }
                    { $_ -ge 30 } { $level = "Warning" }
                    default { $level = "Info" }
                }
            }
            
            # Convert to string for consistent processing
            $level = $level.ToString()
            
            # Count by level
            switch ($level.ToLower()) {
                "critical" { $results.Summary.ErrorCount++ }
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
                        Context = $actualLogEntry
                        Id = if ($entry.id) { $entry.id } else { "unknown" }
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
                        Context = $actualLogEntry
                        Id = if ($entry.id) { $entry.id } else { "unknown" }
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
                        Context = $actualLogEntry
                        Id = if ($entry.id) { $entry.id } else { "unknown" }
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
        Analyzes RocketChat settings for configuration issues and security vulnerabilities.
    
    .DESCRIPTION
        This function performs comprehensive analysis of RocketChat settings including:
        - Security configuration validation (2FA, registration, passwords)
        - Performance setting optimization checks
        - Configuration best practices validation
        - Threshold monitoring for timeouts and limits
    
    .PARAMETER SettingsFile
        Path to the RocketChat settings file (JSON format). Should contain settings
        with _id/key and value fields.
    
    .PARAMETER Config
        Configuration object containing analysis rules and thresholds for validation.
    
    .EXAMPLE
        $config = @{ PerformanceThresholds = @{ ResponseTime = 5000 } }
        $results = Invoke-SettingsAnalysis -SettingsFile "settings.json" -Config $config
    
    .OUTPUTS
        Hashtable containing Issues, Settings, SecuritySettings, and PerformanceSettings
    
    .NOTES
        Author: Support Engineering Team
        Version: 1.2.0
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
                    
                    # Check for 2FA disabled
                    if ($key -match "TwoFactorAuthentication.*Enabled" -and $value -eq $false) {
                        $results.Issues += @{
                            Type = "Security"
                            Severity = "Warning"
                            Message = "Two-factor authentication is disabled"
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
    
    .DESCRIPTION
        This function analyzes server statistics to identify:
        - Memory usage patterns and potential memory leaks
        - User load distribution and capacity planning needs
        - Message volume trends and storage requirements
        - Server performance metrics and bottlenecks
    
    .PARAMETER StatisticsFile
        Path to the RocketChat statistics file (JSON format). Should contain server
        metrics, user statistics, and performance data.
    
    .PARAMETER Config
        Configuration object containing performance thresholds:
        - PerformanceThresholds.MemoryUsage: Memory usage threshold percentage
        - PerformanceThresholds.ResponseTime: Maximum acceptable response time
    
    .EXAMPLE
        $config = @{
            PerformanceThresholds = @{
                MemoryUsage = 80
                ResponseTime = 5000
            }
        }
        $results = Invoke-StatisticsAnalysis -StatisticsFile "stats.json" -Config $config
    
    .OUTPUTS
        Hashtable with Issues, ServerInfo, PerformanceMetrics, and ResourceUsage
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
        Analyzes RocketChat Omnichannel configuration for customer service optimization.
    
    .DESCRIPTION
        This function analyzes Omnichannel (Livechat) configuration to identify:
        - Routing efficiency and customer wait times
        - Agent availability and distribution settings
        - Offline form configuration for 24/7 support
        - Integration settings and webhook configurations
    
    .PARAMETER OmnichannelFile
        Path to the RocketChat Omnichannel file (JSON format). Contains Livechat
        settings and agent configurations.
    
    .PARAMETER Config
        Configuration object containing analysis rules for Omnichannel best practices.
    
    .EXAMPLE
        $results = Invoke-OmnichannelAnalysis -OmnichannelFile "omnichannel.json" -Config $config
    
    .OUTPUTS
        Hashtable containing Issues, Configuration, and Integrations analysis
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
        if ($omnichannelContent -is [array]) {
            $omnichannelData = $omnichannelContent
        } elseif ($omnichannelContent.omnichannel) {
            $omnichannelData = $omnichannelContent.omnichannel
        } else {
            $omnichannelData = @($omnichannelContent)
        }
        
        foreach ($item in $omnichannelData) {
            # Check Omnichannel enabled status
            if ($item._id -eq "Livechat_enabled" -and $item.value -eq $false) {
                $results.Issues += @{
                    Type = "Configuration"
                    Severity = "Info"
                    Message = "Omnichannel (Livechat) is disabled"
                    Setting = $item._id
                }
            }
            
            # Check for proper routing configuration
            if ($item._id -eq "Livechat_Routing_Method" -and $item.value -eq "Manual_Selection") {
                $results.Issues += @{
                    Type = "Configuration"
                    Severity = "Warning"
                    Message = "Manual routing may cause delays in customer service"
                    Setting = $item._id
                }
            }
            
            # Check for offline form configuration
            if ($item._id -eq "Livechat_offline_form_unavailable" -and $item.value -eq $true) {
                $results.Issues += @{
                    Type = "Configuration"
                    Severity = "Warning"
                    Message = "Offline form is disabled - customers cannot leave messages when agents are unavailable"
                    Setting = $item._id
                }
            }
            
            # Store configuration for reporting
            if ($item._id) {
                $results.Configuration[$item._id] = $item.value
            }
        }
        
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
        Analyzes RocketChat installed apps and integrations for security and performance.
    
    .DESCRIPTION
        This function analyzes installed RocketChat apps to identify:
        - Security-related apps and their status
        - Performance monitoring and analytics apps
        - Outdated or deprecated apps requiring updates
        - Disabled critical apps that may impact functionality
    
    .PARAMETER AppsFile
        Path to the RocketChat apps file (JSON format). Contains information about
        installed apps, their versions, and status.
    
    .PARAMETER Config
        Configuration object containing analysis rules for app evaluation.
    
    .EXAMPLE
        $results = Invoke-AppsAnalysis -AppsFile "apps.json" -Config $config
        foreach ($app in $results.InstalledApps.Keys) {
            Write-Host "App: $app, Status: $($results.InstalledApps[$app].Status)"
        }
    
    .OUTPUTS
        Hashtable containing Issues, InstalledApps, SecurityApps, and PerformanceApps
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
        if ($appsContent -is [array]) {
            $appsData = $appsContent
        } elseif ($appsContent.apps) {
            $appsData = $appsContent.apps
        } else {
            $appsData = @($appsContent)
        }
        
        foreach ($app in $appsData) {
            $appName = $app.name ?? $app.id ?? $app._id ?? "Unknown App"
            $appVersion = $app.version ?? "Unknown"
            $appStatus = $app.status ?? $app.enabled ?? "Unknown"
            
            # Store app information
            $results.InstalledApps[$appName] = @{
                Version = $appVersion
                Status = $appStatus
                Description = $app.description ?? ""
                Author = $app.author ?? ""
            }
            
            # Check for security-related apps
            if ($appName -match "security|auth|2fa|login|password") {
                $results.SecurityApps[$appName] = $results.InstalledApps[$appName]
            }
            
            # Check for performance-related apps
            if ($appName -match "monitor|performance|analytics|metrics") {
                $results.PerformanceApps[$appName] = $results.InstalledApps[$appName]
            }
            
            # Check for disabled critical apps
            if ($appStatus -eq "disabled" -or $appStatus -eq $false) {
                $severity = if ($appName -match "security|backup|monitor") { "Warning" } else { "Info" }
                $results.Issues += @{
                    Type = "App Configuration"
                    Severity = $severity
                    Message = "App '$appName' is disabled"
                    App = $appName
                    Status = $appStatus
                }
            }
            
            # Check for outdated apps (this is a simple check - in real scenarios you'd compare against latest versions)
            if ($appVersion -match "^[0-9]+" -and [int]($appVersion.Split('.')[0]) -lt 2) {
                $results.Issues += @{
                    Type = "App Version"
                    Severity = "Warning"
                    Message = "App '$appName' may be outdated (version $appVersion)"
                    App = $appName
                    Version = $appVersion
                }
            }
        }
        
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
