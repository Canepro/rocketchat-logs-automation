# RocketChat Log Analyzer - Easy Report Generator
param(
    [Parameter(Mandatory=$true)]
    [string]$DumpPath,
    
    [string]$OutputName
)

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if (-not $OutputName) {
    $OutputName = "RocketChat-Report-$timestamp.html"
}

$downloadsPath = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
$outputPath = Join-Path $downloadsPath $OutputName

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RocketChat Log Analyzer - Report Generator" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Analyzing dump: $DumpPath" -ForegroundColor Green
Write-Host "Output location: $outputPath" -ForegroundColor Green
Write-Host ""

try {
    # Convert Windows path to WSL path
    $driveLetter = $DumpPath.Substring(0,1).ToLower()
    $wslDumpPath = "/mnt/$driveLetter" + $DumpPath.Substring(2).Replace('\', '/')
    
    $outputDriveLetter = $outputPath.Substring(0,1).ToLower() 
    $wslOutputPath = "/mnt/$outputDriveLetter" + $outputPath.Substring(2).Replace('\', '/')
    
    Write-Host "Starting analysis..." -ForegroundColor Yellow
    
    # Run via WSL
    wsl bash ./analyze-rocketchat-dump.sh --format html --output "`"$wslOutputPath`"" --verbose "`"$wslDumpPath`""
    
    if (Test-Path $outputPath) {
        Write-Host ""
        Write-Host "SUCCESS! Report Generated" -ForegroundColor Green
        Write-Host "Report saved to: $outputPath" -ForegroundColor White
        Write-Host ""
        
        $openReport = Read-Host "Open report now? (Y/N)"
        if ($openReport -match '^[Yy]') {
            Start-Process $outputPath
        }
    } else {
        throw "Report file was not created"
    }
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = Read-Host
