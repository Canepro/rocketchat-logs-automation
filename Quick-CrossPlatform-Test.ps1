#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick Cross-Platform Test - PowerShell & Bash Versions
    
.DESCRIPTION
    Runs both PowerShell and Bash versions of the RocketChat analyzer with real support dump files
    and generates HTML output for comparison. This validates feature parity and functionality.

.PARAMETER DumpPath
    Path to real RocketChat support dump directory

.EXAMPLE
    .\Quick-CrossPlatform-Test.ps1 -DumpPath "C:\Users\i\Downloads\7.8.0-support-dump"
    
.EXAMPLE
    # Use default dump (auto-detect latest)
    .\Quick-CrossPlatform-Test.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DumpPath = ""
)

# Colors for output
$Green = "`e[32m"
$Red = "`e[31m"
$Yellow = "`e[33m"
$Cyan = "`e[36m"
$White = "`e[37m"
$Reset = "`e[0m"

Write-Host "${Cyan}🚀 RocketChat Analyzer - Quick Cross-Platform Test${Reset}" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Auto-detect dump path if not provided
if ([string]::IsNullOrEmpty($DumpPath)) {
    Write-Host "${Yellow}🔍 Auto-detecting RocketChat support dump...${Reset}" -ForegroundColor Yellow
    
    $possiblePaths = @(
        "C:\Users\i\Downloads\7.8.0-support-dump",
        "C:\Users\i\Downloads\7.5.1-support-dump", 
        "C:\Users\i\Downloads\7.2.0-support-dump",
        "C:\Users\i\Downloads\7.1.0-support-dump"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $DumpPath = $path
            Write-Host "${Green}✅ Found dump: $DumpPath${Reset}" -ForegroundColor Green
            break
        }
    }
    
    if ([string]::IsNullOrEmpty($DumpPath)) {
        Write-Host "${Red}❌ No RocketChat support dump found in Downloads folder${Reset}" -ForegroundColor Red
        Write-Host "Please specify -DumpPath parameter with a valid dump directory" -ForegroundColor Red
        exit 1
    }
}

# Validate dump path exists
if (-not (Test-Path $DumpPath)) {
    Write-Host "${Red}❌ Dump path does not exist: $DumpPath${Reset}" -ForegroundColor Red
    exit 1
}

$dumpName = (Get-Item $DumpPath).Name
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"

Write-Host "${Green}📊 Testing with dump: $dumpName${Reset}" -ForegroundColor Green
Write-Host ""

# Test 1: PowerShell Version
Write-Host "${Cyan}🔸 TEST 1: PowerShell Version${Reset}" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Gray

$psOutputPath = "powershell-test-$timestamp.html"
$psStartTime = Get-Date

try {
    Write-Host "Running: .\Analyze-RocketChatDump.ps1 -DumpPath `"$DumpPath`" -OutputFormat HTML -ExportPath `"$psOutputPath`""
    & ".\Analyze-RocketChatDump.ps1" -DumpPath $DumpPath -OutputFormat HTML -ExportPath $psOutputPath -ErrorAction Stop
    $psEndTime = Get-Date
    $psDuration = ($psEndTime - $psStartTime).TotalSeconds
    
    if (Test-Path $psOutputPath) {
        $psFileSize = [math]::Round((Get-Item $psOutputPath).Length / 1KB, 2)
        Write-Host "${Green}✅ PowerShell test completed successfully${Reset}" -ForegroundColor Green
        Write-Host "   📄 Output: $psOutputPath ($psFileSize KB)" -ForegroundColor Green
        Write-Host "   ⏱️  Duration: $([math]::Round($psDuration, 2)) seconds" -ForegroundColor Green
    } else {
        Write-Host "${Red}❌ PowerShell test failed - no output file generated${Reset}" -ForegroundColor Red
    }
} catch {
    Write-Host "${Red}❌ PowerShell test failed with error: $($_.Exception.Message)${Reset}" -ForegroundColor Red
}

Write-Host ""

# Test 2: Bash Version (via WSL or Git Bash)
Write-Host "${Cyan}🔸 TEST 2: Bash Version${Reset}" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Gray

$bashOutputPath = "bash-test-$timestamp.html"
$bashStartTime = Get-Date

# Try different bash environments
$bashCommands = @(
    "wsl bash ./analyze-rocketchat-dump.sh --format html --output `"$bashOutputPath`" `"/mnt/c/Users/i/Downloads/$dumpName`"",
    "bash ./analyze-rocketchat-dump.sh --format html --output `"$bashOutputPath`" `"$DumpPath`""
)

$bashSuccess = $false
foreach ($cmd in $bashCommands) {
    try {
        Write-Host "Trying: $cmd"
        
        if ($cmd.StartsWith("wsl")) {
            # WSL command
            $wslDumpPath = "/mnt/c/Users/i/Downloads/$dumpName"
            Write-Host "Using WSL path: $wslDumpPath"
            & wsl bash ./analyze-rocketchat-dump.sh --format html --output $bashOutputPath $wslDumpPath
        } else {
            # Direct bash command
            & bash ./analyze-rocketchat-dump.sh --format html --output $bashOutputPath $DumpPath
        }
        
        $bashEndTime = Get-Date
        $bashDuration = ($bashEndTime - $bashStartTime).TotalSeconds
        
        if (Test-Path $bashOutputPath) {
            $bashFileSize = [math]::Round((Get-Item $bashOutputPath).Length / 1KB, 2)
            Write-Host "${Green}✅ Bash test completed successfully${Reset}" -ForegroundColor Green
            Write-Host "   📄 Output: $bashOutputPath ($bashFileSize KB)" -ForegroundColor Green
            Write-Host "   ⏱️  Duration: $([math]::Round($bashDuration, 2)) seconds" -ForegroundColor Green
            $bashSuccess = $true
            break
        }
    } catch {
        Write-Host "${Yellow}⚠️  Bash attempt failed: $($_.Exception.Message)${Reset}" -ForegroundColor Yellow
        continue
    }
}

if (-not $bashSuccess) {
    Write-Host "${Red}❌ All Bash test attempts failed${Reset}" -ForegroundColor Red
    Write-Host "${Yellow}💡 Make sure WSL is installed or Git Bash is available${Reset}" -ForegroundColor Yellow
}

Write-Host ""

# Summary
Write-Host "${Cyan}📋 TEST SUMMARY${Reset}" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

Write-Host "🎯 Dump Analyzed: $dumpName" -ForegroundColor White
Write-Host "📅 Test Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White

if (Test-Path $psOutputPath) {
    Write-Host "${Green}✅ PowerShell Version: SUCCESS${Reset}" -ForegroundColor Green
    Write-Host "   📄 Report: $psOutputPath" -ForegroundColor Green
} else {
    Write-Host "${Red}❌ PowerShell Version: FAILED${Reset}" -ForegroundColor Red
}

if (Test-Path $bashOutputPath) {
    Write-Host "${Green}✅ Bash Version: SUCCESS${Reset}" -ForegroundColor Green  
    Write-Host "   📄 Report: $bashOutputPath" -ForegroundColor Green
} else {
    Write-Host "${Red}❌ Bash Version: FAILED${Reset}" -ForegroundColor Red
}

Write-Host ""

# Open reports if both succeeded
if ((Test-Path $psOutputPath) -and (Test-Path $bashOutputPath)) {
    Write-Host "${Green}🎉 Both versions completed successfully!${Reset}" -ForegroundColor Green
    Write-Host "${Cyan}🌐 Opening HTML reports for comparison...${Reset}" -ForegroundColor Cyan
    
    Start-Sleep -Seconds 2
    
    # Open PowerShell report
    try {
        Start-Process $psOutputPath
        Write-Host "   🔗 Opened PowerShell report in browser" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Could not auto-open PowerShell report" -ForegroundColor Yellow
    }
    
    Start-Sleep -Seconds 1
    
    # Open Bash report  
    try {
        Start-Process $bashOutputPath
        Write-Host "   🔗 Opened Bash report in browser" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Could not auto-open Bash report" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "${Cyan}💡 Compare the two HTML reports to verify feature parity!${Reset}" -ForegroundColor Cyan
    Write-Host "   Both should show identical analysis results and formatting." -ForegroundColor Gray
    
} elseif (Test-Path $psOutputPath) {
    Write-Host "${Yellow}⚠️  Only PowerShell version succeeded${Reset}" -ForegroundColor Yellow
    Write-Host "${Cyan}🌐 Opening PowerShell report...${Reset}" -ForegroundColor Cyan
    try {
        Start-Process $psOutputPath
    } catch {
        Write-Host "   ⚠️  Could not auto-open report" -ForegroundColor Yellow
    }
    
} elseif (Test-Path $bashOutputPath) {
    Write-Host "${Yellow}⚠️  Only Bash version succeeded${Reset}" -ForegroundColor Yellow
    Write-Host "${Cyan}🌐 Opening Bash report...${Reset}" -ForegroundColor Cyan
    try {
        Start-Process $bashOutputPath
    } catch {
        Write-Host "   ⚠️  Could not auto-open report" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "${Red}❌ Both versions failed - check error messages above${Reset}" -ForegroundColor Red
}

Write-Host ""
Write-Host "${Cyan}✨ Cross-platform test completed!${Reset}" -ForegroundColor Cyan
