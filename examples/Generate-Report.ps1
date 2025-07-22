# RocketChat Log Analyzer - Easy Report Generator
# This PowerShell script generates HTML reports and saves them to your Downloads folder

param(
    [Parameter(Mandatory=$true, HelpMessage="Path to RocketChat dump folder")]
    [string]$DumpPath,
    
    [Parameter(HelpMessage="Custom output filename (optional)")]
    [string]$OutputName
)

# Set up paths and filename
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if (-not $OutputName) {
    $OutputName = "RocketChat-Report-$timestamp.html"
}

$downloadsPath = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
$outputPath = Join-Path $downloadsPath $OutputName

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RocketChat Log Analyzer - Report Generator" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📁 Analyzing dump: " -NoNewline -ForegroundColor Green
Write-Host $DumpPath -ForegroundColor White

Write-Host "💾 Output location: " -NoNewline -ForegroundColor Green  
Write-Host $outputPath -ForegroundColor White
Write-Host ""

try {
    # First, try to use the PowerShell script directly (more reliable)
    Write-Host "🚀 Starting analysis using PowerShell analyzer..." -ForegroundColor Yellow
    
    # Use the PowerShell analyzer directly
    $analysisResult = & ".\Analyze-RocketChatDump.ps1" -DumpPath $DumpPath -OutputFormat HTML -ExportPath $outputPath
    
    if (Test-Path $outputPath) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "   SUCCESS! Report Generated" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 Report saved to: " -NoNewline -ForegroundColor Green
        Write-Host $outputPath -ForegroundColor White
        Write-Host ""
        
        # Ask if user wants to open the report
        $openReport = Read-Host "Would you like to open the report now? (Y/N)"
        if ($openReport -match '^[Yy]') {
            Write-Host "🌐 Opening report in your default browser..." -ForegroundColor Yellow
            Start-Process $outputPath
        }
        
        Write-Host ""
        Write-Host "✅ Analysis complete! You can find your report in the Downloads folder." -ForegroundColor Green
    } else {
        # Fallback to WSL bash script
        Write-Host "⚠️ Fallback: Trying WSL bash script..." -ForegroundColor Yellow
        
        # Simple approach for Windows to WSL path conversion
        $driveLetter = $DumpPath.Substring(0,1).ToLower()
        $wslDumpPath = "/mnt/$driveLetter" + $DumpPath.Substring(2).Replace('\', '/')
        
        $outputDriveLetter = $outputPath.Substring(0,1).ToLower() 
        $wslOutputPath = "/mnt/$outputDriveLetter" + $outputPath.Substring(2).Replace('\', '/')
        
        # Run the bash script via WSL
        $bashCommand = "bash ./analyze-rocketchat-dump.sh --format html --output `"$wslOutputPath`" --verbose `"$wslDumpPath`""
        
        # Execute the command
        wsl $bashCommand
        
        if (-not (Test-Path $outputPath)) {
            throw "Report file was not created by either PowerShell or bash analyzer"
        }
    }
}
catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "   ERROR! Report Generation Failed" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "   • Check that the dump path exists and is accessible" -ForegroundColor White
    Write-Host "   • Ensure WSL is installed and working" -ForegroundColor White
    Write-Host "   • Verify the bash script is in the current directory" -ForegroundColor White
    Write-Host ""
}

Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
