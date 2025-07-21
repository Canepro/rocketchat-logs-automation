# Minimal test of New-HTMLReport function
Import-Module ".\modules\ReportGenerator.psm1" -Force

$simpleResults = @{
    SettingsAnalysis = @{
        SecuritySettings = @(@{Issue = "Test"; Severity = "High"})
        PerformanceSettings = @()
        Settings = @{Count = 1}
    }
    LogAnalysis = @{ Issues = @() }
    StatisticsAnalysis = @{ Issues = @() }
}

Write-Host "Calling New-HTMLReport..." -ForegroundColor Yellow
$html = New-HTMLReport -Results $simpleResults
Write-Host "Function returned content of length: $($html.Length)" -ForegroundColor Green

# Count HTML tags directly in the string
$htmlMatches = [regex]::Matches($html, '<html')
Write-Host "Number of <html> tags found: $($htmlMatches.Count)" -ForegroundColor Cyan

# Save to file
$html | Out-File "minimal-test.html" -Encoding UTF8
Write-Host "Saved to minimal-test.html" -ForegroundColor Green
