# Test simplified HTML generation
try {
    # Import modules
    $ModulesPath = Join-Path $PSScriptRoot "modules"
    Import-Module (Join-Path $ModulesPath "RocketChatLogParser.psm1") -Force
    Import-Module (Join-Path $ModulesPath "RocketChatAnalyzer.psm1") -Force  
    Import-Module (Join-Path $ModulesPath "ReportGenerator.psm1") -Force

    Write-Host "Modules imported successfully" -ForegroundColor Green

    # Create simple HTML content
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test Report</title>
</head>
<body>
    <h1>Simple Test Report</h1>
    <p>This is a test to verify basic HTML generation works.</p>
</body>
</html>
"@

    Write-Host "Simple HTML created. Length: $($html.Length)" -ForegroundColor Green
    $html | Out-File -FilePath "simple-test.html" -Encoding UTF8
    Write-Host "Simple HTML saved successfully" -ForegroundColor Green

    # Now test if the issue is with the complex here-string in New-HTMLReport
    Write-Host "Testing complex string interpolation..." -ForegroundColor Yellow
    
    $TestResults = @{
        LogAnalysis = @{
            Summary = @{
                TotalEntries = 100
                ErrorCount = 5
                WarningCount = 10
            }
            Issues = @()
        }
    }
    
    $healthScore = Get-HealthScore -AnalysisResults $TestResults
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $testHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Test Complex Report</title>
</head>
<body>
    <h1>Health Score: $($healthScore.OverallScore)%</h1>
    <p>Generated at: $timestamp</p>
</body>
</html>
"@
    
    Write-Host "Complex HTML created. Length: $($testHtml.Length)" -ForegroundColor Green
    $testHtml | Out-File -FilePath "complex-test.html" -Encoding UTF8
    Write-Host "Complex HTML saved successfully" -ForegroundColor Green

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}
