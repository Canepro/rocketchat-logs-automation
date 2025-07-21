<#
.SYNOPSIS
    Quick test script for RocketChat Dump Analyzer

.DESCRIPTION
    This script tests the analyzer with sample data to verify everything is working correctly.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$TestDumpPath = "C:\Users\i\Downloads\7.8.0-support-dump _1_"
)

Write-Host "🚀 RocketChat Dump Analyzer - Quick Test" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Gray

# Check if PowerShell version is adequate
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "❌ PowerShell 5.1 or later is required" -ForegroundColor Red
    exit 1
}

Write-Host "✅ PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# Check if modules exist
$modulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) "modules"
$requiredModules = @(
    "RocketChatLogParser.psm1",
    "RocketChatAnalyzer.psm1", 
    "ReportGenerator.psm1"
)

foreach ($module in $requiredModules) {
    $modulePath = Join-Path $modulesPath $module
    if (Test-Path $modulePath) {
        Write-Host "✅ Module found: $module" -ForegroundColor Green
    } else {
        Write-Host "❌ Module missing: $module" -ForegroundColor Red
        exit 1
    }
}

# Check if config file exists
$configPath = Join-Path (Split-Path $PSScriptRoot -Parent) "config\analysis-rules.json"
if (Test-Path $configPath) {
    Write-Host "✅ Configuration file found" -ForegroundColor Green
} else {
    Write-Host "❌ Configuration file missing" -ForegroundColor Red
    exit 1
}

# Check if main script exists
$mainScript = Join-Path (Split-Path $PSScriptRoot -Parent) "scripts\Analyze-RocketChatDump.ps1"
if (Test-Path $mainScript) {
    Write-Host "✅ Main script found" -ForegroundColor Green
} else {
    Write-Host "❌ Main script missing" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔍 Testing with sample dump..." -ForegroundColor Yellow

# Test with provided dump path if it exists
if (Test-Path $TestDumpPath) {
    Write-Host "✅ Test dump found at: $TestDumpPath" -ForegroundColor Green
    
    Write-Host "`n🔬 Running analysis..." -ForegroundColor Cyan
    try {
        & $mainScript -DumpPath $TestDumpPath -Severity Warning -Verbose
        Write-Host "`n✅ Analysis completed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "`n❌ Analysis failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️ Test dump not found at: $TestDumpPath" -ForegroundColor Yellow
    Write-Host "To test with your dump files, run:" -ForegroundColor Cyan
    Write-Host ".\Analyze-RocketChatDump.ps1 -DumpPath 'C:\Path\To\Your\Dump'" -ForegroundColor White
}

Write-Host "`n📖 For more examples, see:" -ForegroundColor Cyan
Write-Host "   examples\usage-examples.md" -ForegroundColor White
Write-Host "   README.md" -ForegroundColor White

Write-Host "`n🎉 Setup verification complete!" -ForegroundColor Green
