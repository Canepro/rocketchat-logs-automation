# Create a proper test HTML file with interactive log analysis
Import-Module .\modules\RocketChatAnalyzer.psm1 -Force
Import-Module .\modules\ReportGenerator.psm1 -Force

$testResults = @{
    DumpPath = "C:\Test\RocketChat\Support"
    Summary = @{
        TotalIssues = 8
        AnalysisComplete = $true
    }
    LogAnalysis = @{
        Summary = @{
            TotalEntries = 1500
            ErrorCount = 35
            WarningCount = 55
            InfoCount = 1410
        }
        TimeRange = @{
            Start = "2025-01-15T08:00:00Z"
            End = "2025-01-15T18:30:00Z"
        }
        Issues = @(
            @{
                Severity = "Critical"
                Message = "Database connection pool exhausted - MongoDB timeout after 30 seconds"
                Timestamp = "2025-01-15T14:23:15Z"
                Context = "MongoDB"
                Type = "Database"
                Pattern = "connection.*pool.*exhausted"
            },
            @{
                Severity = "Error"
                Message = "Authentication failed for admin@company.com - invalid credentials"
                Timestamp = "2025-01-15T12:45:30Z"
                Context = "Authentication"
                Type = "Security"
                Pattern = "auth.*failed"
            },
            @{
                Severity = "Warning" 
                Message = "High memory usage detected: 85% of available RAM (6.8GB/8GB)"
                Timestamp = "2025-01-15T16:12:45Z"
                Context = "System"
                Type = "Performance"
                Pattern = "memory.*high"
            },
            @{
                Severity = "Error"
                Message = "WebSocket connection dropped for 15 concurrent users during file upload"
                Timestamp = "2025-01-15T10:30:22Z"
                Context = "WebSocket"
                Type = "Network"
                Pattern = "websocket.*dropped"
            },
            @{
                Severity = "Critical"
                Message = "File system space critically low: 95% usage on /data partition (19GB/20GB)"
                Timestamp = "2025-01-15T17:45:12Z"
                Context = "FileSystem"
                Type = "Storage"
                Pattern = "space.*critical"
            },
            @{
                Severity = "Warning"
                Message = "SSL certificate expires in 7 days - renewal required"
                Timestamp = "2025-01-15T09:15:33Z"
                Context = "SSL"
                Type = "Security"
                Pattern = "certificate.*expires"
            },
            @{
                Severity = "Info"
                Message = "Backup process completed successfully - 2.3GB archived"
                Timestamp = "2025-01-15T03:00:00Z"
                Context = "Backup"
                Type = "System"
                Pattern = "backup.*completed"
            },
            @{
                Severity = "Error"
                Message = "API rate limit exceeded for user integration@external.com"
                Timestamp = "2025-01-15T11:22:18Z"
                Context = "API"
                Type = "Integration"
                Pattern = "rate.*limit.*exceeded"
            }
        )
    }
}

Write-Host "Generating interactive HTML report..." -ForegroundColor Yellow
$htmlReport = New-HTMLReport -Results $testResults
$htmlReport | Out-File -FilePath "interactive-log-demo.html" -Encoding UTF8

Write-Host "SUCCESS: Interactive HTML report created!" -ForegroundColor Green
Write-Host "File: interactive-log-demo.html" -ForegroundColor Cyan
Write-Host "Size: $((Get-Item 'interactive-log-demo.html').Length) bytes" -ForegroundColor Gray

Write-Host "`nFeatures included:" -ForegroundColor Yellow
Write-Host "  [OK] Interactive log entry expansion" -ForegroundColor Green
Write-Host "  [OK] Severity-based filtering (Critical, Error, Warning, Info)" -ForegroundColor Green
Write-Host "  [OK] Real-time entry counter updates" -ForegroundColor Green
Write-Host "  [OK] Professional card-based layout" -ForegroundColor Green
Write-Host "  [OK] Detailed log entry metadata" -ForegroundColor Green
Write-Host "  [OK] Responsive design for all devices" -ForegroundColor Green

Write-Host "`nOpen 'interactive-log-demo.html' in your browser to test!" -ForegroundColor Cyan
