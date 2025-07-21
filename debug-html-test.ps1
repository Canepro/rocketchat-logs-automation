# Debug HTML generation to trace duplicate issue
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

Write-Host "Starting HTML generation debug..." -ForegroundColor Yellow

# Call the function and capture result
$html = New-HTMLReport -Results $simpleResults

Write-Host "Function completed. Analyzing output..." -ForegroundColor Green

# Check for multiple HTML documents
$htmlTags = [regex]::Matches($html, '<html[^>]*>')
$doctypeTags = [regex]::Matches($html, '<!DOCTYPE[^>]*>')
$closingHtmlTags = [regex]::Matches($html, '</html>')

Write-Host "HTML Analysis:" -ForegroundColor Cyan
Write-Host "  DOCTYPE tags: $($doctypeTags.Count)" -ForegroundColor White
Write-Host "  Opening <html> tags: $($htmlTags.Count)" -ForegroundColor White  
Write-Host "  Closing </html> tags: $($closingHtmlTags.Count)" -ForegroundColor White
Write-Host "  Total content length: $($html.Length)" -ForegroundColor White

# Find positions of HTML tags
for ($i = 0; $i -lt $htmlTags.Count; $i++) {
    $pos = $htmlTags[$i].Index
    $lineNum = ($html.Substring(0, $pos) -split "`n").Length
    Write-Host "  HTML tag $($i+1) at position $pos (approx line $lineNum)" -ForegroundColor Yellow
}

# Save with debug info
$html | Out-File "debug-html-test.html" -Encoding UTF8
Write-Host "Saved debug output to debug-html-test.html" -ForegroundColor Green

# Also check if we can split the content to see where duplication starts
$htmlSplit = $html -split '<html'
Write-Host "HTML split analysis: $($htmlSplit.Count) parts" -ForegroundColor Magenta
if ($htmlSplit.Count -gt 2) {
    Write-Host "Second HTML document starts with: $($htmlSplit[2].Substring(0, 100))..." -ForegroundColor Red
}
