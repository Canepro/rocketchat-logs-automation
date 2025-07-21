# Simple Cross-Platform Test for Interactive Log Analysis
# Compatible with both PowerShell 5.1 and PowerShell Core 7.x

Write-Host "Testing Interactive Log Analysis Features" -ForegroundColor Yellow
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White

# Import the required modules
try {
    Import-Module .\modules\RocketChatAnalyzer.psm1 -Force
    Import-Module .\modules\ReportGenerator.psm1 -Force
    Write-Host "SUCCESS: Modules imported" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Module import failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create simple test data
$testResults = @{
    DumpPath = "C:\Test\RocketChat\Support"
    Summary = @{
        TotalIssues = 6
        AnalysisComplete = $true
    }
    LogAnalysis = @{
        Summary = @{
            TotalEntries = 1000
            ErrorCount = 20
            WarningCount = 30
            InfoCount = 950
        }
        TimeRange = @{
            Start = "2025-01-15T08:00:00Z"
            End = "2025-01-15T18:30:00Z"
        }
        Issues = @(
            @{
                Severity = "Critical"
                Message = "Database connection failed"
                Timestamp = "2025-01-15T14:23:15Z"
                Context = "MongoDB"
                Type = "Database"
            },
            @{
                Severity = "Error"
                Message = "Authentication failed"
                Timestamp = "2025-01-15T12:45:30Z"
                Context = "Auth"
                Type = "Security"
            },
            @{
                Severity = "Warning"
                Message = "High memory usage"
                Timestamp = "2025-01-15T16:12:45Z"
                Context = "System"
                Type = "Performance"
            }
        )
    }
}

# Test HTML generation
Write-Host "`nTesting HTML generation..." -ForegroundColor Yellow
try {
    $htmlReport = New-HTMLReport -Results $testResults
    Write-Host "SUCCESS: HTML report generated ($($htmlReport.Length) chars)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: HTML generation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test for key interactive features
Write-Host "`nChecking interactive features..." -ForegroundColor Yellow

$tests = @{
    "JavaScript toggle function" = "toggleLogEntry"
    "JavaScript filter function" = "filterLogEntries"
    "Log entry CSS class" = "log-entry-item"
    "Filter bar CSS class" = "log-filter-bar"
    "Interactive details CSS" = "log-entry-details"
    "Filter button CSS" = "filter-button"
}

foreach ($testName in $tests.Keys) {
    $searchTerm = $tests[$testName]
    if ($htmlReport.Contains($searchTerm)) {
        Write-Host "  PASS: $testName" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: $testName (missing: $searchTerm)" -ForegroundColor Red
    }
}

# Test severity filtering
Write-Host "`nChecking severity filters..." -ForegroundColor Yellow
$severityTests = @("critical", "error", "warning", "info")
foreach ($severity in $severityTests) {
    if ($htmlReport.ToLower().Contains($severity)) {
        Write-Host "  PASS: $severity filter" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: $severity filter" -ForegroundColor Red
    }
}

# Test file output
Write-Host "`nTesting file output..." -ForegroundColor Yellow
$testFile = "test-report-simple.html"
try {
    $htmlReport | Out-File -FilePath $testFile -Encoding UTF8
    $fileExists = Test-Path $testFile
    if ($fileExists) {
        $fileSize = (Get-Item $testFile).Length
        Write-Host "  PASS: File created ($fileSize bytes)" -ForegroundColor Green
        Remove-Item $testFile -Force
    } else {
        Write-Host "  FAIL: File not created" -ForegroundColor Red
    }
} catch {
    Write-Host "  ERROR: File output failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Platform-specific tests
Write-Host "`nTesting cross-platform features..." -ForegroundColor Yellow

# Test GUID generation
try {
    $testGuid = [System.Guid]::NewGuid().ToString()
    Write-Host "  PASS: GUID generation" -ForegroundColor Green
} catch {
    Write-Host "  FAIL: GUID generation" -ForegroundColor Red
}

# Test random numbers
try {
    $testRandom = Get-Random -Minimum 1000 -Maximum 9999
    Write-Host "  PASS: Random number generation" -ForegroundColor Green
} catch {
    Write-Host "  FAIL: Random number generation" -ForegroundColor Red
}

# Test date formatting
try {
    $testDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    Write-Host "  PASS: Date formatting" -ForegroundColor Green
} catch {
    Write-Host "  FAIL: Date formatting" -ForegroundColor Red
}

Write-Host "`nTest completed for PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Yellow

if ($PSVersionTable.PSVersion.Major -ge 6) {
    Write-Host "Running on PowerShell Core - Cross-platform ready" -ForegroundColor Green
} else {
    Write-Host "Running on Windows PowerShell 5.1 - Legacy compatible" -ForegroundColor Green
}
