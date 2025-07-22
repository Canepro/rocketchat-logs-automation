# Debug HTML Report Generation
try {
    # Import modules
    $ModulesPath = Join-Path $PSScriptRoot "modules"
    Import-Module (Join-Path $ModulesPath "RocketChatLogParser.psm1") -Force
    Import-Module (Join-Path $ModulesPath "RocketChatAnalyzer.psm1") -Force  
    Import-Module (Join-Path $ModulesPath "ReportGenerator.psm1") -Force

    Write-Host "Modules imported successfully" -ForegroundColor Green

    # Create test data
    $TestResults = @{
        LogAnalysis = @{
            Summary = @{
                TotalEntries = 100
                ErrorCount = 5
                WarningCount = 10
            }
            Issues = @()
        }
        SettingsAnalysis = @{
            Summary = @{
                TotalSettings = 50
                SecurityIssues = 2
            }
            Issues = @()
        }
    }

    Write-Host "Test data created" -ForegroundColor Green

    # Test Get-HealthScore function first
    Write-Host "Testing Get-HealthScore..." -ForegroundColor Yellow
    try {
        $healthScore = Get-HealthScore -AnalysisResults $TestResults
        Write-Host "HealthScore: $($healthScore | ConvertTo-Json -Depth 3)" -ForegroundColor Green
    } catch {
        Write-Host "ERROR in Get-HealthScore: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # Test New-HTMLReport function
    Write-Host "Calling New-HTMLReport..." -ForegroundColor Yellow
    try {
        $report = New-HTMLReport -Results $TestResults
        
        if ($report) {
            Write-Host "Report generated successfully. Length: $($report.Length)" -ForegroundColor Green
            $report | Out-File -FilePath "test-debug.html" -Encoding UTF8
            Write-Host "Report saved to test-debug.html" -ForegroundColor Green
        } else {
            Write-Host "ERROR: Report is null or empty!" -ForegroundColor Red
        }
    } catch {
        Write-Host "ERROR in New-HTMLReport: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
    }

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}
