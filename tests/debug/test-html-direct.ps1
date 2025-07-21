# Direct test of HTML generation to verify the fix
Import-Module ".\modules\RocketChatLogParser.psm1" -Force
Import-Module ".\modules\RocketChatAnalyzer.psm1" -Force  
Import-Module ".\modules\ReportGenerator.psm1" -Force

$config = @{ 
    PerformanceThresholds = @{ 
        MemoryUsage = 80
        ResponseTime = 5000 
    } 
}

Write-Host "Testing direct HTML generation..." -ForegroundColor Yellow

# Analyze settings
$settingsResult = Invoke-SettingsAnalysis -SettingsFile ".\test-dump\standard-dump.json" -Config $config
Write-Host "Settings analysis complete:" -ForegroundColor Green
Write-Host "  Security: $($settingsResult.SecuritySettings.Count)" -ForegroundColor Cyan
Write-Host "  Performance: $($settingsResult.PerformanceSettings.Count)" -ForegroundColor Cyan
Write-Host "  Total: $($settingsResult.Settings.Count)" -ForegroundColor Cyan

# Create full analysis results structure
$AnalysisResults = @{
    SettingsAnalysis = $settingsResult
    StatisticsAnalysis = @{ 
        Issues = @()
        ServerInfo = @{}
        PerformanceMetrics = @{}
    }
    LogAnalysis = @{ 
        Issues = @()
        LogEntries = @{}
    }
}

# Generate HTML
Write-Host "Generating HTML report..." -ForegroundColor Yellow
$htmlContent = New-HTMLReport -Results $AnalysisResults

# Save and check
$htmlContent | Out-File "direct-test-report.html" -Encoding UTF8
Write-Host "HTML report saved to: direct-test-report.html" -ForegroundColor Green

# Extract counts from HTML
if ($htmlContent -match 'font-size: 1\.2em; font-weight: bold; color: #dc3545.*?>(\d+)<') {
    Write-Host "Security count in HTML: $($Matches[1])" -ForegroundColor Red
}
if ($htmlContent -match 'font-size: 1\.2em; font-weight: bold; color: #28a745.*?>(\d+)<') {
    Write-Host "Performance count in HTML: $($Matches[1])" -ForegroundColor Green
}

Write-Host "Test completed!" -ForegroundColor Yellow
