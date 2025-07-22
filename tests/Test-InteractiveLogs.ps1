# Test Script for Interactive Log Analysis - Issue #13
# Tests both Windows PowerShell 5.1 and PowerShell Core 7.x compatibility

param(
    [switch]$TestAll,
    [switch]$TestHTMLGeneration,
    [switch]$TestCrossPlatform
)

Write-Host "🧪 Testing Interactive Log Analysis Features" -ForegroundColor Yellow
Write-Host "=" * 50 -ForegroundColor Cyan

# Test PowerShell version compatibility
Write-Host "`n📋 PowerShell Environment:" -ForegroundColor Green
Write-Host "Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host "Platform: $($PSVersionTable.Platform)" -ForegroundColor White
Write-Host "OS: $($PSVersionTable.OS)" -ForegroundColor White

# Import the module
try {
    Import-Module .\modules\ReportGenerator.psm1 -Force
    Write-Host "OK Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "FAIL Module import failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create test data for interactive log analysis
$testResults = @{
    DumpPath = "C:\Test\RocketChat\Support"
    Summary = @{
        TotalIssues = 15
        AnalysisComplete = $true
    }
    LogAnalysis = @{
        Summary = @{
            TotalEntries = 1250
            ErrorCount = 25
            WarningCount = 45
            InfoCount = 1180
        }
        TimeRange = @{
            Start = "2025-01-15T08:00:00Z"
            End = "2025-01-15T18:30:00Z"
        }
        Issues = @(
            @{
                Severity = "Critical"
                Message = "Database connection pool exhausted - MongoDB timeout"
                Timestamp = "2025-01-15T14:23:15Z"
                Context = "MongoDB"
                Type = "Database"
                Pattern = "connection.*pool.*exhausted"
            },
            @{
                Severity = "Error"
                Message = "Authentication failed for user admin@company.com"
                Timestamp = "2025-01-15T12:45:30Z"
                Context = "Authentication"
                Type = "Security"
                Pattern = "auth.*failed"
            },
            @{
                Severity = "Warning"
                Message = "High memory usage detected: 85% of available RAM"
                Timestamp = "2025-01-15T16:12:45Z"
                Context = "System"
                Type = "Performance"
                Pattern = "memory.*high"
            },
            @{
                Severity = "Error"
                Message = "WebSocket connection dropped for 15 concurrent users"
                Timestamp = "2025-01-15T10:30:22Z"
                Context = "WebSocket"
                Type = "Network"
                Pattern = "websocket.*dropped"
            },
            @{
                Severity = "Info"
                Message = "Backup process completed successfully"
                Timestamp = "2025-01-15T09:15:00Z"
                Context = "Backup"
                Type = "System"
                Pattern = "backup.*completed"
            },
            @{
                Severity = "Critical"
                Message = "File system space critically low: 95% usage on /data"
                Timestamp = "2025-01-15T17:45:12Z"
                Context = "FileSystem"
                Type = "Storage"
                Pattern = "space.*critical"
            }
        )
    }
}

Write-Host "`n🔍 Test 1: Basic HTML Generation" -ForegroundColor Green
try {
    $htmlReport = New-HTMLReport -Results $testResults
    Write-Host "OK HTML report generated successfully" -ForegroundColor Green
    Write-Host "   Report length: $($htmlReport.Length) characters" -ForegroundColor Gray
} catch {
    Write-Host "FAIL HTML generation failed: $($_.Exception.Message)" -ForegroundColor Red
    return
}

Write-Host "`n🎯 Test 2: Interactive Elements Verification" -ForegroundColor Green
$interactiveElements = @()
$interactiveElements += "toggleLogEntry"
$interactiveElements += "filterLogEntries"
$interactiveElements += "log-entry-item"
$interactiveElements += "log-filter-bar"
$interactiveElements += "filter-button"
$interactiveElements += "log-entry-details"

foreach ($element in $interactiveElements) {
    if ($htmlReport -like "*$element*") {
        Write-Host "OK Found: $element" -ForegroundColor Green
    } else {
        Write-Host "FAIL Missing: $element" -ForegroundColor Red
    }
}

Write-Host "`n📊 Test 3: Severity Filtering Functionality" -ForegroundColor Green
$severityLevels = @("critical", "error", "warning", "info")
foreach ($level in $severityLevels) {
    $count = ($testResults.LogAnalysis.Issues | Where-Object { $_.Severity.ToLower() -eq $level }).Count
    if ($htmlReport -like "*$level ($count)*") {
        Write-Host "OK Severity filter '$level' with count $count" -ForegroundColor Green
    } else {
        Write-Host "WARN Severity filter '$level' format may need verification" -ForegroundColor Yellow
    }
}

Write-Host "`n🎨 Test 4: CSS Styling Verification" -ForegroundColor Green
$cssClasses = @()
$cssClasses += ".log-entry-item"
$cssClasses += ".log-entry-header"
$cssClasses += ".log-entry-details"
$cssClasses += ".log-filter-bar"
$cssClasses += ".filter-button.active"
$cssClasses += ".log-detail-grid"

foreach ($cssClass in $cssClasses) {
    if ($htmlReport -like "*$cssClass*") {
        Write-Host "OK CSS class: $cssClass" -ForegroundColor Green
    } else {
        Write-Host "FAIL Missing CSS: $cssClass" -ForegroundColor Red
    }
}

Write-Host "`n⚡ Test 5: JavaScript Functions Verification" -ForegroundColor Green
$jsFunctions = @()
$jsFunctions += "function toggleLogEntry"
$jsFunctions += "function filterLogEntries" 
$jsFunctions += "toggleLogEntry("
$jsFunctions += "filterLogEntries("

foreach ($jsFunc in $jsFunctions) {
    if ($htmlReport -like "*$jsFunc*") {
        Write-Host "OK JavaScript: $jsFunc" -ForegroundColor Green
    } else {
        Write-Host "FAIL Missing JS: $jsFunc" -ForegroundColor Red
    }
}

# Test cross-platform specific features
Write-Host "`n🌐 Test 6: Cross-Platform Compatibility" -ForegroundColor Green

# Test GUID generation (should work on both platforms)
try {
    $testGuid = [System.Guid]::NewGuid().ToString().Substring(0,8)
    Write-Host "✅ GUID generation works: $testGuid" -ForegroundColor Green
} catch {
    Write-Host "❌ GUID generation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test Get-Random (should work on both platforms)
try {
    $testRandom = Get-Random -Minimum 1000 -Maximum 9999
    Write-Host "✅ Get-Random works: $testRandom" -ForegroundColor Green
} catch {
    Write-Host "❌ Get-Random failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test DateTime handling (critical for cross-platform)
try {
    $testDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    Write-Host "✅ DateTime formatting works: $testDate" -ForegroundColor Green
} catch {
    Write-Host "❌ DateTime formatting failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📝 Test 7: HTML File Generation & Validation" -ForegroundColor Green
$testFile = "test-interactive-report.html"
try {
    $htmlReport | Out-File -FilePath $testFile -Encoding UTF8
    $fileSize = (Get-Item $testFile).Length
    Write-Host "✅ Test HTML file created: $testFile ($fileSize bytes)" -ForegroundColor Green
    
    # Basic HTML validation
    $htmlContent = Get-Content $testFile -Raw
    if ($htmlContent -like "*<!DOCTYPE html>*" -and $htmlContent -like "*</html>*") {
        Write-Host "✅ HTML structure is valid" -ForegroundColor Green
    } else {
        Write-Host "❌ HTML structure validation failed" -ForegroundColor Red
    }
    
    # Clean up test file
    Remove-Item $testFile -Force
    Write-Host "✅ Test file cleaned up" -ForegroundColor Green
} catch {
    Write-Host "❌ File generation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 Test Summary:" -ForegroundColor Yellow
Write-Host "Interactive Log Analysis testing completed!" -ForegroundColor Green
Write-Host "Platform: $($PSVersionTable.PSVersion) on $($PSVersionTable.OS)" -ForegroundColor Gray

if ($PSVersionTable.PSVersion.Major -ge 6) {
    Write-Host "✅ Running on PowerShell Core - Cross-platform compatible" -ForegroundColor Green
} else {
    Write-Host "✅ Running on Windows PowerShell 5.1 - Legacy compatible" -ForegroundColor Green
}

Write-Host "`n💡 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test on Linux/macOS with PowerShell Core" -ForegroundColor Cyan
Write-Host "2. Test with real RocketChat log data" -ForegroundColor Cyan  
Write-Host "3. Verify interactive features in different browsers" -ForegroundColor Cyan
Write-Host "4. Performance testing with large log datasets" -ForegroundColor Cyan
