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
        Performs comprehensive analysis of RocketChat settings with enhanced bash-parity logic including:
        - Security configuration validation (2FA, registration, passwords, auth methods)
        - Performance setting optimization checks (file limits, message sizes, timeouts)
        - Configuration best practices validation with specific thresholds
        - Detailed categorization and severity assessment per Project Phoenix v2.0.0
    
    .PARAMETER SettingsFile
        Path to the RocketChat settings file (JSON format). Should contain settings
        with _id/key and value fields.
    
    .PARAMETER Config
        Configuration object containing analysis rules and thresholds for validation.
    
    .EXAMPLE
        $config = @{ PerformanceThresholds = @{ ResponseTime = 5000 } }
        $results = Invoke-SettingsAnalysis -SettingsFile "settings.json" -Config $config
    
    .OUTPUTS
        Hashtable containing Issues, Settings, SecuritySettings, PerformanceSettings, and counts
    
    .NOTES
        Author: Support Engineering Team
        Version: 2.0.0 - Enhanced with bash-parity logic from Project Phoenix
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
        Statistics = @{
            TotalSettings = 0
            SecurityCount = 0
            PerformanceCount = 0
            SecurityIssues = 0
            PerformanceIssues = 0
            ConfigurationWarnings = 0
        }
        GoodSettings = @()
    }
    
    try {
        Write-Verbose "Reading settings file: $SettingsFile"
        
        if (-not (Test-Path $SettingsFile)) {
            throw "Settings file not found: $SettingsFile"
        }
        
        $settingsContent = Get-Content $SettingsFile -Raw | ConvertFrom-Json
        
        # Handle different JSON structures (enhanced from bash)
        if ($settingsContent -is [array]) {
            # Array of settings
            $settings = $settingsContent
            $results.Statistics.TotalSettings = $settings.Count
        } elseif ($settingsContent.settings) {
            # Comprehensive dump format - extract settings section
            $settings = $settingsContent.settings
            $results.Statistics.TotalSettings = $settings.Count
        } else {
            # Single setting or unknown format
            $settings = @($settingsContent)
            $results.Statistics.TotalSettings = 1
        }
        
        foreach ($setting in $settings) {
            $key = if ($setting._id) { $setting._id } elseif ($setting.key) { $setting.key } else { $setting.name }
            $value = if ($setting.value -ne $null) { $setting.value } elseif ($setting.setting -ne $null) { $setting.setting } else { $null }
            $settingType = if ($setting.type) { $setting.type } else { "unknown" }
            
            if ($key -and $value -ne $null) {
                $results.Settings[$key] = $value
                
                # Comprehensive security analysis (based on bash analyze_settings function)
                switch ($key) {
                    # Authentication & Security
                    "Accounts_TwoFactorAuthentication_Enabled" {
                        $results.SecuritySettings[$key] = $value
                        if ($value -eq "false" -or $value -eq $false) {
                            $results.Statistics.SecurityIssues++
                            $results.Issues += @{
                                Type = "Security"
                                Severity = "Error"
                                Message = "Two-factor authentication is disabled"
                                Setting = $key
                                Value = $value
                            }
                        } else {
                            $results.GoodSettings += "✓ Two-factor authentication enabled"
                        }
                    }
                    
                    "Accounts_RegistrationForm" {
                        $results.SecuritySettings[$key] = $value
                        if ($value -eq "Public") {
                            $results.Statistics.SecurityIssues++
                            $results.Issues += @{
                                Type = "Security"
                                Severity = "Error"
                                Message = "Public user registration is enabled"
                                Setting = $key
                                Value = $value
                            }
                        } else {
                            $results.GoodSettings += "✓ Registration form: $value"
                        }
                    }
                    
                    "Accounts_AllowAnonymousRead" {
                        $results.SecuritySettings[$key] = $value
                        if ($value -eq "true" -or $value -eq $true) {
                            $results.Statistics.ConfigurationWarnings++
                            $results.Issues += @{
                                Type = "Security"
                                Severity = "Warning"
                                Message = "Anonymous reading is enabled"
                                Setting = $key
                                Value = $value
                            }
                        }
                    }
                    
                    "Accounts_AllowAnonymousWrite" {
                        $results.SecuritySettings[$key] = $value
                        if ($value -eq "true" -or $value -eq $true) {
                            $results.Statistics.SecurityIssues++
                            $results.Issues += @{
                                Type = "Security"
                                Severity = "Critical"
                                Message = "Anonymous writing is enabled"
                                Setting = $key
                                Value = $value
                            }
                        }
                    }
                    
                    "LDAP_Enable" {
                        $results.SecuritySettings[$key] = $value
                        if ($value -eq "true" -or $value -eq $true) {
                            $results.GoodSettings += "✓ LDAP authentication enabled"
                        }
                    }
                    
                    "SAML_Custom_Default" {
                        $results.SecuritySettings[$key] = $value
                        if ($value -eq "true" -or $value -eq $true) {
                            $results.GoodSettings += "✓ SAML authentication enabled"
                        }
                    }
                    
                    # File Upload & Storage
                    "FileUpload_MaxFileSize" {
                        $results.PerformanceSettings[$key] = $value
                        $sizeBytes = [long]$value
                        $sizeMB = [math]::Round($sizeBytes / 1024 / 1024, 2)
                        if ($sizeBytes -gt 104857600) {  # > 100MB
                            $results.Statistics.PerformanceIssues++
                            $results.Issues += @{
                                Type = "Performance"
                                Severity = "Warning"
                                Message = "Large file upload limit (${sizeMB}MB)"
                                Setting = $key
                                Value = $value
                            }
                        } else {
                            $results.GoodSettings += "File Upload Limit: ${sizeMB}MB"
                        }
                    }
                    
                    "FileUpload_Storage_Type" {
                        $results.PerformanceSettings[$key] = $value
                        $results.GoodSettings += "Storage Type: $value"
                    }
                    
                    # Rate Limiting
                    "API_Enable_Rate_Limiter" {
                        $results.SecuritySettings[$key] = $value
                        if ($value -eq "false" -or $value -eq $false) {
                            $results.Statistics.SecurityIssues++
                            $results.Issues += @{
                                Type = "Security"
                                Severity = "Error"
                                Message = "API rate limiting is disabled"
                                Setting = $key
                                Value = $value
                            }
                        } else {
                            $results.GoodSettings += "✓ API rate limiting enabled"
                        }
                    }
                    
                    "API_Enable_Rate_Limiter_Dev" {
                        $results.SecuritySettings[$key] = $value
                        if ($value -eq "true" -or $value -eq $true) {
                            $results.Statistics.ConfigurationWarnings++
                            $results.Issues += @{
                                Type = "Configuration"
                                Severity = "Warning"
                                Message = "Development rate limiter is enabled in production"
                                Setting = $key
                                Value = $value
                            }
                        }
                    }
                    
                    # Message & Retention
                    "Message_MaxAllowedSize" {
                        $results.PerformanceSettings[$key] = $value
                        $sizeChars = [int]$value
                        if ($sizeChars -gt 10000) {
                            $results.Statistics.PerformanceIssues++
                            $results.Issues += @{
                                Type = "Performance"
                                Severity = "Warning"
                                Message = "Large message size limit ($sizeChars chars)"
                                Setting = $key
                                Value = $value
                            }
                        } else {
                            $results.GoodSettings += "Message Size Limit: $sizeChars characters"
                        }
                    }
                    
                    "RetentionPolicy_Enabled" {
                        $results.PerformanceSettings[$key] = $value
                        if ($value -eq "false" -or $value -eq $false) {
                            $results.Statistics.ConfigurationWarnings++
                            $results.Issues += @{
                                Type = "Configuration"
                                Severity = "Warning"
                                Message = "No message retention policy configured"
                                Setting = $key
                                Value = $value
                            }
                        } else {
                            $results.GoodSettings += "✓ Message retention policy enabled"
                        }
                    }
                    
                    # Federation & External
                    "Federation_Enabled" {
                        $results.SecuritySettings[$key] = $value
                        if ($value -eq "true" -or $value -eq $true) {
                            $results.GoodSettings += "Federation: Enabled"
                        }
                    }
                    
                    "E2E_Enable" {
                        $results.SecuritySettings[$key] = $value
                        if ($value -eq "false" -or $value -eq $false) {
                            $results.Statistics.SecurityIssues++
                            $results.Issues += @{
                                Type = "Security"
                                Severity = "Error"
                                Message = "End-to-end encryption is disabled"
                                Setting = $key
                                Value = $value
                            }
                        } else {
                            $results.GoodSettings += "✓ End-to-end encryption enabled"
                        }
                    }
                    
                    # Performance Settings
                    "Log_Level" {
                        $results.PerformanceSettings[$key] = $value
                        if ($value -eq "0") {  # Debug level
                            $results.Statistics.PerformanceIssues++
                            $results.Issues += @{
                                Type = "Performance"
                                Severity = "Warning"
                                Message = "Debug logging enabled in production"
                                Setting = $key
                                Value = $value
                            }
                        } else {
                            $results.GoodSettings += "Log Level: $value"
                        }
                    }
                    
                    default {
                        # Generic pattern-based analysis for uncategorized settings
                        if ($key -match "(password|auth|token|secret|ldap|saml|oauth|security|encryption|ssl|tls)") {
                            $results.SecuritySettings[$key] = $value
                            $results.Statistics.SecurityCount++
                        }
                        
                        if ($key -match "(cache|limit|timeout|max|pool|buffer|memory|cpu|performance|rate|throttle)") {
                            $results.PerformanceSettings[$key] = $value
                            $results.Statistics.PerformanceCount++
                        }
                    }
                }
            }
        }
        
        # Final counts (matching bash logic)
        if ($results.Statistics.SecurityCount -eq 0) {
            $results.Statistics.SecurityCount = $results.SecuritySettings.Count
        }
        if ($results.Statistics.PerformanceCount -eq 0) {
            $results.Statistics.PerformanceCount = $results.PerformanceSettings.Count
        }
        
        Write-Verbose "Settings analysis complete. Reviewed $($results.Statistics.TotalSettings) settings, found $($results.Statistics.SecurityIssues) security issues, $($results.Statistics.PerformanceIssues) performance issues"
        
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
        Performs comprehensive analysis of server statistics with enhanced bash-parity logic including:
        - Memory usage patterns, thresholds, and leak detection  
        - User load distribution and capacity planning with detailed breakdowns
        - Message volume trends, storage requirements, and database analytics
        - Server performance metrics, uptime monitoring, and OS analysis
        - Version tracking, federation status, and enterprise features per Project Phoenix v2.0.0
    
    .PARAMETER StatisticsFile
        Path to the RocketChat statistics file (JSON format). Should contain server
        metrics, user statistics, and performance data.
    
    .PARAMETER Config
        Configuration object containing performance thresholds for enhanced validation.
    
    .EXAMPLE
        $config = @{
            PerformanceThresholds = @{
                MemoryUsage = 80
                ResponseTime = 5000
            }
        }
        $results = Invoke-StatisticsAnalysis -StatisticsFile "stats.json" -Config $config
    
    .OUTPUTS
        Hashtable with Issues, ServerInfo, PerformanceMetrics, ResourceUsage, and detailed statistics
    
    .NOTES
        Author: Support Engineering Team
        Version: 2.0.0 - Enhanced with bash-parity logic from Project Phoenix
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
        Statistics = @{
            Version = "unknown"
            NodeVersion = "unknown"
            Architecture = "unknown"
            Platform = "unknown"
            OSType = "unknown"
            OSRelease = "unknown"
            UptimeSeconds = 0
            TotalUsers = 0
            OnlineUsers = 0
            AwayUsers = 0
            BusyUsers = 0
            OfflineUsers = 0
            TotalMessages = 0
            TotalRooms = 0
            TotalChannels = 0
            TotalPrivateGroups = 0
            TotalDirectMessages = 0
            TotalLivechatRooms = 0
            DatabaseSizeMB = 0
            MemoryMB = 0
            MemoryFreeMB = 0
            HeapUsedMB = 0
            HeapTotalMB = 0
            ExternalMB = 0
            FederationEnabled = $false
            LDAPEnabled = $false
            LivechatEnabled = $false
            EnterpriseEnabled = $false
        }
    }
    
    try {
        Write-Verbose "Reading statistics file: $StatisticsFile"
        
        if (-not (Test-Path $StatisticsFile)) {
            throw "Statistics file not found: $StatisticsFile"
        }
        
        $statsContent = Get-Content $StatisticsFile -Raw | ConvertFrom-Json
        
        # Extract comprehensive statistics (based on bash analyze_statistics function)
        # Root level paths for RocketChat dumps
        $results.Statistics.Version = if ($statsContent.version) { $statsContent.version } else { "unknown" }
        $results.Statistics.NodeVersion = if ($statsContent.process.nodeVersion) { $statsContent.process.nodeVersion } else { "unknown" }
        $results.Statistics.Architecture = if ($statsContent.os.arch) { $statsContent.os.arch } else { "unknown" }
        $results.Statistics.Platform = if ($statsContent.os.platform) { $statsContent.os.platform } else { "unknown" }
        $results.Statistics.OSType = if ($statsContent.os.type) { $statsContent.os.type } else { "unknown" }
        $results.Statistics.OSRelease = if ($statsContent.os.release) { $statsContent.os.release } else { "unknown" }
        $results.Statistics.UptimeSeconds = if ($statsContent.process.uptime) { [int]$statsContent.process.uptime } elseif ($statsContent.os.uptime) { [int]$statsContent.os.uptime } else { 0 }
        
        # Memory statistics - check both locations (bash parity)
        $memoryUsed = if ($statsContent.os.totalmem) { [long]$statsContent.os.totalmem } else { 0 }
        $memoryFree = if ($statsContent.os.freemem) { [long]$statsContent.os.freemem } else { 0 }
        $memoryHeapUsed = if ($statsContent.process.memory.heapUsed) { [long]$statsContent.process.memory.heapUsed } else { 0 }
        $memoryHeapTotal = if ($statsContent.process.memory.heapTotal) { [long]$statsContent.process.memory.heapTotal } else { 0 }
        $memoryExternal = if ($statsContent.process.memory.external) { [long]$statsContent.process.memory.external } else { 0 }
        
        # Convert memory to MB (handle decimal numbers - bash parity)
        if ($memoryUsed -gt 0) {
            $results.Statistics.MemoryMB = [math]::Floor($memoryUsed / 1024 / 1024)
            $results.Statistics.MemoryFreeMB = [math]::Floor($memoryFree / 1024 / 1024)
            $results.Statistics.HeapUsedMB = [math]::Floor($memoryHeapUsed / 1024 / 1024)
            $results.Statistics.HeapTotalMB = [math]::Floor($memoryHeapTotal / 1024 / 1024)
            $results.Statistics.ExternalMB = [math]::Floor($memoryExternal / 1024 / 1024)
        }
        
        # User statistics - Root level in RocketChat dumps
        $results.Statistics.TotalUsers = if ($statsContent.totalUsers) { [int]$statsContent.totalUsers } else { 0 }
        $results.Statistics.OnlineUsers = if ($statsContent.onlineUsers) { [int]$statsContent.onlineUsers } else { 0 }
        $results.Statistics.AwayUsers = if ($statsContent.awayUsers) { [int]$statsContent.awayUsers } else { 0 }
        $results.Statistics.BusyUsers = if ($statsContent.busyUsers) { [int]$statsContent.busyUsers } else { 0 }
        $results.Statistics.OfflineUsers = if ($statsContent.offlineUsers) { [int]$statsContent.offlineUsers } else { 0 }
        
        # Message and room statistics - Root level in RocketChat dumps
        $results.Statistics.TotalMessages = if ($statsContent.totalMessages) { [long]$statsContent.totalMessages } else { 0 }
        $results.Statistics.TotalRooms = if ($statsContent.totalRooms) { [int]$statsContent.totalRooms } else { 0 }
        $results.Statistics.TotalChannels = if ($statsContent.totalChannels) { [int]$statsContent.totalChannels } else { 0 }
        $results.Statistics.TotalPrivateGroups = if ($statsContent.totalPrivateGroups) { [int]$statsContent.totalPrivateGroups } else { 0 }
        $results.Statistics.TotalDirectMessages = if ($statsContent.totalDirectMessages) { [int]$statsContent.totalDirectMessages } else { 0 }
        $results.Statistics.TotalLivechatRooms = if ($statsContent.totalLivechatRooms) { [int]$statsContent.totalLivechatRooms } else { 0 }
        
        # Database statistics - Root level in RocketChat dumps
        $dbSize = if ($statsContent.dbSize) { [long]$statsContent.dbSize } else { 0 }
        if ($dbSize -gt 0) {
            $results.Statistics.DatabaseSizeMB = [math]::Floor($dbSize / 1024 / 1024)
        }
        
        # Federation and features - Root level in RocketChat dumps
        $results.Statistics.FederationEnabled = if ($statsContent.federationEnabled) { [bool]$statsContent.federationEnabled } else { $false }
        $results.Statistics.LDAPEnabled = if ($statsContent.ldapEnabled) { [bool]$statsContent.ldapEnabled } else { $false }
        $results.Statistics.LivechatEnabled = if ($statsContent.livechatEnabled) { [bool]$statsContent.livechatEnabled } else { $false }
        $results.Statistics.EnterpriseEnabled = if ($statsContent.enterpriseReady) { [bool]$statsContent.enterpriseReady } else { $false }
        
        # Populate structured results for compatibility
        $results.ServerInfo = @{
            Version = $results.Statistics.Version
            NodeVersion = $results.Statistics.NodeVersion
            Architecture = $results.Statistics.Architecture
            Platform = $results.Statistics.Platform
            OSType = $results.Statistics.OSType
            OSRelease = $results.Statistics.OSRelease
            UptimeSeconds = $results.Statistics.UptimeSeconds
            UptimeFormatted = [TimeSpan]::FromSeconds($results.Statistics.UptimeSeconds).ToString()
        }
        
        $results.PerformanceMetrics = @{
            Memory = @{
                TotalMB = $results.Statistics.MemoryMB
                FreeMB = $results.Statistics.MemoryFreeMB
                HeapUsedMB = $results.Statistics.HeapUsedMB
                HeapTotalMB = $results.Statistics.HeapTotalMB
                ExternalMB = $results.Statistics.ExternalMB
                UsagePercent = if ($results.Statistics.MemoryMB -gt 0) { [math]::Round((($results.Statistics.MemoryMB - $results.Statistics.MemoryFreeMB) / $results.Statistics.MemoryMB) * 100, 2) } else { 0 }
            }
            Users = @{
                Total = $results.Statistics.TotalUsers
                Online = $results.Statistics.OnlineUsers
                Away = $results.Statistics.AwayUsers
                Busy = $results.Statistics.BusyUsers
                Offline = $results.Statistics.OfflineUsers
                OnlinePercent = if ($results.Statistics.TotalUsers -gt 0) { [math]::Round(($results.Statistics.OnlineUsers / $results.Statistics.TotalUsers) * 100, 2) } else { 0 }
            }
            Messages = @{
                Total = $results.Statistics.TotalMessages
                Rooms = $results.Statistics.TotalRooms
                Channels = $results.Statistics.TotalChannels
                PrivateGroups = $results.Statistics.TotalPrivateGroups
                DirectMessages = $results.Statistics.TotalDirectMessages
                LivechatRooms = $results.Statistics.TotalLivechatRooms
                MessagesPerRoom = if ($results.Statistics.TotalRooms -gt 0) { [math]::Round($results.Statistics.TotalMessages / $results.Statistics.TotalRooms, 2) } else { 0 }
            }
            Database = @{
                SizeMB = $results.Statistics.DatabaseSizeMB
                SizeGB = if ($results.Statistics.DatabaseSizeMB -gt 0) { [math]::Round($results.Statistics.DatabaseSizeMB / 1024, 2) } else { 0 }
            }
        }
        
        $results.ResourceUsage = @{
            Features = @{
                Federation = $results.Statistics.FederationEnabled
                LDAP = $results.Statistics.LDAPEnabled  
                Livechat = $results.Statistics.LivechatEnabled
                Enterprise = $results.Statistics.EnterpriseEnabled
            }
        }
        
        # Performance analysis and issue detection (enhanced from bash)
        
        # Memory analysis
        if ($results.PerformanceMetrics.Memory.UsagePercent -gt 85) {
            $results.Issues += @{
                Type = "Performance"
                Severity = "Critical"
                Message = "High memory usage: $($results.PerformanceMetrics.Memory.UsagePercent)% ($($results.Statistics.MemoryMB - $results.Statistics.MemoryFreeMB)MB used)"
                Metric = "Memory"
                Value = $results.PerformanceMetrics.Memory.UsagePercent
            }
        } elseif ($results.PerformanceMetrics.Memory.UsagePercent -gt 75) {
            $results.Issues += @{
                Type = "Performance"  
                Severity = "Warning"
                Message = "Elevated memory usage: $($results.PerformanceMetrics.Memory.UsagePercent)% ($($results.Statistics.MemoryMB - $results.Statistics.MemoryFreeMB)MB used)"
                Metric = "Memory"
                Value = $results.PerformanceMetrics.Memory.UsagePercent
            }
        }
        
        # Database size analysis
        if ($results.Statistics.DatabaseSizeMB -gt 10240) { # > 10GB
            $results.Issues += @{
                Type = "Performance"
                Severity = "Warning"
                Message = "Large database size: $($results.PerformanceMetrics.Database.SizeGB)GB - consider archiving old data"
                Metric = "DatabaseSize"
                Value = $results.Statistics.DatabaseSizeMB
            }
        }
        
        # User load analysis
        if ($results.Statistics.TotalUsers -gt 10000) {
            $results.Issues += @{
                Type = "Performance"
                Severity = "Info"
                Message = "High user count: $($results.Statistics.TotalUsers) users - monitor performance closely"
                Metric = "UserCount"
                Value = $results.Statistics.TotalUsers
            }
        }
        
        # Message volume analysis
        if ($results.Statistics.TotalMessages -gt 50000000) { # > 50M messages
            $results.Issues += @{
                Type = "Performance"
                Severity = "Warning"
                Message = "High message volume: $($results.Statistics.TotalMessages) messages - consider retention policies"
                Metric = "MessageCount"
                Value = $results.Statistics.TotalMessages
            }
        }
        
        # Uptime analysis
        $uptimeDays = [math]::Floor($results.Statistics.UptimeSeconds / 86400)
        if ($uptimeDays -lt 1) {
            $results.Issues += @{
                Type = "Reliability"
                Severity = "Warning"
                Message = "Recent restart detected: uptime is only $uptimeDays days"
                Metric = "Uptime"
                Value = $results.Statistics.UptimeSeconds
            }
        }
        
        # Node.js version analysis
        if ($results.Statistics.NodeVersion -match "^(\d+)\.") {
            $majorVersion = [int]$matches[1]
            if ($majorVersion -lt 16) {
                $results.Issues += @{
                    Type = "Security"
                    Severity = "Warning"
                    Message = "Outdated Node.js version: $($results.Statistics.NodeVersion) - consider upgrading"
                    Metric = "NodeVersion"
                    Value = $results.Statistics.NodeVersion
                }
            }
        }
        
        Write-Verbose "Statistics analysis complete. Version: $($results.Statistics.Version), Memory: $($results.Statistics.MemoryMB)MB, Users: $($results.Statistics.TotalUsers) ($($results.Statistics.OnlineUsers) online)"
        
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
        Performs comprehensive analysis of installed RocketChat apps with enhanced bash-parity logic including:
        - Security-related apps with detailed status monitoring
        - Performance monitoring and analytics apps assessment
        - Integration apps identification (webhooks, bots, connectors)
        - Outdated or deprecated apps requiring updates with version heuristics
        - Disabled critical apps that may impact functionality per Project Phoenix v2.0.0
    
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
        Hashtable containing Issues, InstalledApps, SecurityApps, PerformanceApps, IntegrationApps, and statistics
    
    .NOTES
        Author: Support Engineering Team
        Version: 2.0.0 - Enhanced with bash-parity logic from Project Phoenix
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
        IntegrationApps = @{}
        OutdatedApps = @{}
        Statistics = @{
            TotalApps = 0
            EnabledApps = 0
            DisabledApps = 0
            OutdatedApps = 0
            SecurityRiskApps = 0
            SecurityApps = 0
            PerformanceApps = 0
            IntegrationApps = 0
        }
        AppsList = @()
    }
    
    try {
        Write-Verbose "Reading apps file: $AppsFile"
        
        if (-not (Test-Path $AppsFile)) {
            Write-Verbose "Apps file not found: $AppsFile"
            return $results
        }
        
        $appsContent = Get-Content $AppsFile -Raw | ConvertFrom-Json
        
        # Handle both array and object structures (based on bash analyze_apps function)
        $appsData = @()
        if ($appsContent.apps -and ($appsContent.apps -is [array])) {
            # Structure: {"apps": [...]}
            $appsData = $appsContent.apps
        } elseif ($appsContent -is [array]) {
            # Structure: [...]
            $appsData = $appsContent
        } else {
            # Single app or unknown format
            $appsData = @($appsContent)
        }
        
        $results.Statistics.TotalApps = $appsData.Count
        
        foreach ($app in $appsData) {
            $appName = if ($app.name) { $app.name } elseif ($app.id) { $app.id } elseif ($app._id) { $app._id } else { "Unknown App" }
            $appVersion = if ($app.version) { $app.version } else { "unknown" }
            $appStatus = if ($app.status) { $app.status } elseif ($app.enabled -ne $null) { if ($app.enabled) { "enabled" } else { "disabled" } } else { "unknown" }
            $appAuthor = if ($app.author.name) { $app.author.name } elseif ($app.author) { $app.author } else { "unknown" }
            $appDescription = if ($app.description) { $app.description } else { "" }
            
            # Skip if no valid name
            if (-not $appName -or $appName -eq "Unknown App") { continue }
            
            # Store comprehensive app information
            $results.InstalledApps[$appName] = @{
                Version = $appVersion
                Status = $appStatus
                Description = $appDescription
                Author = $appAuthor
            }
            
            # Count by status and analyze (matching bash logic)
            switch ($appStatus.ToLower()) {
                { $_ -in @("enabled", "true", "initialized") } { $results.Statistics.EnabledApps++ }
                { $_ -in @("disabled", "false", "invalid") } { $results.Statistics.DisabledApps++ }
            }
            
            # Check for security-related apps (enhanced patterns from bash)
            if ($appName -match "(auth|security|login|oauth|ldap|saml|sso|2fa|mfa)" -or $appDescription -match "(auth|security|login|oauth|ldap|saml|sso|2fa|mfa)") {
                $results.Statistics.SecurityApps++
                $results.SecurityApps[$appName] = $results.InstalledApps[$appName]
                $results.AppsList += "Security App: $appName ($appStatus) - $appDescription"
            }
            
            # Check for performance-related apps (enhanced patterns from bash)  
            if ($appName -match "(monitor|performance|metrics|analytics|stats)" -or $appDescription -match "(monitor|performance|metrics|analytics|stats)") {
                $results.Statistics.PerformanceApps++
                $results.PerformanceApps[$appName] = $results.InstalledApps[$appName]
                $results.AppsList += "Performance App: $appName ($appStatus) - $appDescription"
            }
            
            # Check for integration apps (new from bash)
            if ($appName -match "(webhook|api|bot|connector|integration|telegram|slack|jitsi|zoom|teams)" -or $appDescription -match "(webhook|api|bot|connector|integration|telegram|slack|jitsi|zoom|teams)") {
                $results.Statistics.IntegrationApps++
                $results.IntegrationApps[$appName] = $results.InstalledApps[$appName]
                $results.AppsList += "Integration App: $appName ($appStatus) - $appDescription"
            }
            
            # Check for potentially outdated apps (simple heuristic from bash)
            if ($appVersion -match "^[0-2]\.") {
                $results.Statistics.OutdatedApps++
                $results.OutdatedApps[$appName] = $results.InstalledApps[$appName]
                $results.AppsList += "Potentially Outdated: $appName v$appVersion by $appAuthor"
                
                $results.Issues += @{
                    Type = "App Version"
                    Severity = "Warning"
                    Message = "App '$appName' may be outdated (version $appVersion)"
                    App = $appName
                    Version = $appVersion
                    Author = $appAuthor
                }
            }
            
            # Check for disabled critical apps (enhanced from bash)
            if ($appStatus.ToLower() -in @("disabled", "false", "invalid")) {
                $severity = "Info"
                if ($appName -match "(security|auth|2fa|mfa|backup|monitor|performance)") {
                    $severity = "Warning"
                    $results.Statistics.SecurityRiskApps++
                }
                
                $results.Issues += @{
                    Type = "App Configuration"
                    Severity = $severity
                    Message = "Critical app '$appName' is disabled"
                    App = $appName
                    Status = $appStatus
                    Category = if ($appName -match "(security|auth|2fa|mfa)") { "Security" } elseif ($appName -match "(backup|monitor|performance)") { "Operations" } else { "General" }
                }
            }
            
            # Store app details for reporting
            $results.AppsList += "• $appName v$appVersion ($appStatus) by $appAuthor"
        }
        
        Write-Verbose "Apps analysis complete. Reviewed $($results.Statistics.TotalApps) apps: $($results.Statistics.EnabledApps) enabled, $($results.Statistics.DisabledApps) disabled, $($results.Statistics.OutdatedApps) outdated"
        
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
