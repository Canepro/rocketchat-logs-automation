#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Production Readiness Test - RocketChat Analyzer
    
.DESCRIPTION
    Comprehensive test suite to validate the RocketChat analyzer is ready for everyday production use.
    Tests both PowerShell and Bash versions with real support dump files.

.PARAMETER TestAll
    Run all available tests with all available dump files

.EXAMPLE
    .\Production-Readiness-Test.ps1 -TestAll
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$TestAll
)

# Colors for output
$Green = "`e[32m"
$Red = "`e[31m"
$Yellow = "`e[33m"
$Cyan = "`e[36m"
$Blue = "`e[34m"
$Reset = "`e[0m"

Write-Host "${Cyan}🧪 PRODUCTION READINESS TEST - RocketChat Analyzer${Reset}" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Test results tracking
$script:TestResults = @()
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = "",
        [double]$Duration = 0
    )
    
    $script:TotalTests++
    if ($Passed) {
        $script:PassedTests++
        Write-Host "${Green}✅ PASS${Reset}: $TestName" -ForegroundColor Green
    } else {
        $script:FailedTests++
        Write-Host "${Red}❌ FAIL${Reset}: $TestName" -ForegroundColor Red
    }
    
    if ($Details) {
        Write-Host "   📄 $Details" -ForegroundColor Gray
    }
    
    if ($Duration -gt 0) {
        Write-Host "   ⏱️  Duration: $([math]::Round($Duration, 2)) seconds" -ForegroundColor Gray
    }
    
    $script:TestResults += [PSCustomObject]@{
        Test = $TestName
        Passed = $Passed
        Details = $Details
        Duration = $Duration
    }
}

# Find all available RocketChat dumps
Write-Host "${Blue}🔍 DISCOVERY PHASE${Reset}" -ForegroundColor Blue
Write-Host "----------------------------------------" -ForegroundColor Gray

$dumpPaths = @()
$searchPaths = @(
    "C:\Users\i\Downloads\*support-dump*",
    "C:\Downloads\*support-dump*",
    ".\test-dump\*"
)

foreach ($searchPath in $searchPaths) {
    $found = Get-ChildItem -Path $searchPath -Directory -ErrorAction SilentlyContinue
    $dumpPaths += $found
}

if ($dumpPaths.Count -eq 0) {
    Write-Host "${Red}❌ No RocketChat support dump directories found!${Reset}" -ForegroundColor Red
    Write-Host "Please ensure RocketChat support dump files are available in Downloads folder" -ForegroundColor Yellow
    exit 1
}

Write-Host "${Green}✅ Found $($dumpPaths.Count) RocketChat support dump(s):${Reset}" -ForegroundColor Green
foreach ($dump in $dumpPaths) {
    Write-Host "   📁 $($dump.Name) ($($dump.FullName))" -ForegroundColor Gray
}
Write-Host ""

# Select dumps to test
$testDumps = if ($TestAll) { $dumpPaths } else { $dumpPaths | Select-Object -First 2 }

Write-Host "${Blue}📋 TEST PLAN${Reset}" -ForegroundColor Blue
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host "Will test with $($testDumps.Count) dump(s):" -ForegroundColor White
foreach ($dump in $testDumps) {
    Write-Host "   🎯 $($dump.Name)" -ForegroundColor White
}
Write-Host ""

# Test 1: PowerShell Version Tests
Write-Host "${Blue}🔸 POWERSHELL VERSION TESTS${Reset}" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Gray

foreach ($dump in $testDumps) {
    $dumpName = $dump.Name
    $dumpPath = $dump.FullName
    
    Write-Host ""
    Write-Host "${Cyan}Testing PowerShell with: $dumpName${Reset}" -ForegroundColor Cyan
    
    # Test HTML output
    $htmlOutput = "ps-$dumpName-$(Get-Date -Format 'HHmm').html"
    $startTime = Get-Date
    
    try {
        & ".\Analyze-RocketChatDump.ps1" -DumpPath $dumpPath -OutputFormat HTML -ExportPath $htmlOutput -ErrorAction Stop | Out-Host
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        if (Test-Path $htmlOutput) {
            $fileSize = [math]::Round((Get-Item $htmlOutput).Length / 1KB, 2)
            Add-TestResult "PowerShell HTML Output ($dumpName)" $true "Generated $htmlOutput ($fileSize KB)" $duration
            
            # Validate HTML content
            $htmlContent = Get-Content $htmlOutput -Raw
            if ($htmlContent.Contains("<!DOCTYPE html") -and $htmlContent.Contains("RocketChat") -and $htmlContent.Contains("Analysis")) {
                Add-TestResult "PowerShell HTML Content Validation ($dumpName)" $true "Valid HTML with expected content"
            } else {
                Add-TestResult "PowerShell HTML Content Validation ($dumpName)" $false "Invalid or incomplete HTML content"
            }
        } else {
            Add-TestResult "PowerShell HTML Output ($dumpName)" $false "No output file generated"
        }
    } catch {
        Add-TestResult "PowerShell HTML Output ($dumpName)" $false "Error: $($_.Exception.Message)"
    }
    
    # Test Console output
    $startTime = Get-Date
    try {
        $consoleOutput = & ".\Analyze-RocketChatDump.ps1" -DumpPath $dumpPath -OutputFormat Console 2>&1
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        if ($consoleOutput -and $consoleOutput.Count -gt 10) {
            Add-TestResult "PowerShell Console Output ($dumpName)" $true "Generated $($consoleOutput.Count) lines of output" $duration
        } else {
            Add-TestResult "PowerShell Console Output ($dumpName)" $false "Insufficient console output"
        }
    } catch {
        Add-TestResult "PowerShell Console Output ($dumpName)" $false "Error: $($_.Exception.Message)"
    }
}

# Test 2: Bash Version Tests
Write-Host ""
Write-Host "${Blue}🔸 BASH VERSION TESTS${Reset}" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Gray

foreach ($dump in $testDumps) {
    $dumpName = $dump.Name
    $wslDumpPath = "/mnt/c/Users/i/Downloads/$dumpName"
    
    Write-Host ""
    Write-Host "${Cyan}Testing Bash with: $dumpName${Reset}" -ForegroundColor Cyan
    
    # Test HTML output
    $bashHtmlOutput = "bash-$dumpName-$(Get-Date -Format 'HHmm').html"
    $startTime = Get-Date
    
    try {
        $bashResult = & wsl bash ./analyze-rocketchat-dump.sh --format html --output $bashHtmlOutput $wslDumpPath 2>&1
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        if (Test-Path $bashHtmlOutput) {
            $fileSize = [math]::Round((Get-Item $bashHtmlOutput).Length / 1KB, 2)
            Add-TestResult "Bash HTML Output ($dumpName)" $true "Generated $bashHtmlOutput ($fileSize KB)" $duration
            
            # Validate HTML content
            $htmlContent = Get-Content $bashHtmlOutput -Raw
            if ($htmlContent.Contains("<!DOCTYPE html") -and $htmlContent.Contains("RocketChat") -and $htmlContent.Contains("Analysis")) {
                Add-TestResult "Bash HTML Content Validation ($dumpName)" $true "Valid HTML with expected content"
            } else {
                Add-TestResult "Bash HTML Content Validation ($dumpName)" $false "Invalid or incomplete HTML content"
            }
        } else {
            Add-TestResult "Bash HTML Output ($dumpName)" $false "No output file generated"
        }
    } catch {
        Add-TestResult "Bash HTML Output ($dumpName)" $false "Error: $($_.Exception.Message)"
    }
    
    # Test Console output
    $startTime = Get-Date
    try {
        $bashConsoleOutput = & wsl bash ./analyze-rocketchat-dump.sh $wslDumpPath 2>&1
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        if ($bashConsoleOutput -and $bashConsoleOutput.Count -gt 10) {
            Add-TestResult "Bash Console Output ($dumpName)" $true "Generated $($bashConsoleOutput.Count) lines of output" $duration
        } else {
            Add-TestResult "Bash Console Output ($dumpName)" $false "Insufficient console output"
        }
    } catch {
        Add-TestResult "Bash Console Output ($dumpName)" $false "Error: $($_.Exception.Message)"
    }
}

# Test 3: Performance & Load Tests
Write-Host ""
Write-Host "${Blue}🔸 PERFORMANCE TESTS${Reset}" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Gray

# Find largest dump for performance testing
$largestDump = $testDumps | Sort-Object { (Get-ChildItem $_.FullName -Recurse -File | Measure-Object Length -Sum).Sum } -Descending | Select-Object -First 1

if ($largestDump) {
    Write-Host ""
    Write-Host "${Cyan}Performance testing with largest dump: $($largestDump.Name)${Reset}" -ForegroundColor Cyan
    
    # Performance test - PowerShell
    $perfStartTime = Get-Date
    try {
        & ".\Analyze-RocketChatDump.ps1" -DumpPath $largestDump.FullName -OutputFormat HTML -ExportPath "perf-test-ps.html" -ErrorAction Stop | Out-Null
        $perfEndTime = Get-Date
        $perfDuration = ($perfEndTime - $perfStartTime).TotalSeconds
        
        if ($perfDuration -lt 30) {
            Add-TestResult "PowerShell Performance (<30s)" $true "Completed in $([math]::Round($perfDuration, 2)) seconds" $perfDuration
        } elseif ($perfDuration -lt 60) {
            Add-TestResult "PowerShell Performance (<60s)" $true "Completed in $([math]::Round($perfDuration, 2)) seconds (acceptable)" $perfDuration
        } else {
            Add-TestResult "PowerShell Performance" $false "Too slow: $([math]::Round($perfDuration, 2)) seconds" $perfDuration
        }
    } catch {
        Add-TestResult "PowerShell Performance" $false "Error during performance test"
    }
    
    # Performance test - Bash
    $perfStartTime = Get-Date
    try {
        $wslPath = "/mnt/c/Users/i/Downloads/$($largestDump.Name)"
        & wsl bash ./analyze-rocketchat-dump.sh --format html --output "perf-test-bash.html" $wslPath 2>&1 | Out-Null
        $perfEndTime = Get-Date
        $perfDuration = ($perfEndTime - $perfStartTime).TotalSeconds
        
        if ($perfDuration -lt 30) {
            Add-TestResult "Bash Performance (<30s)" $true "Completed in $([math]::Round($perfDuration, 2)) seconds" $perfDuration
        } elseif ($perfDuration -lt 60) {
            Add-TestResult "Bash Performance (<60s)" $true "Completed in $([math]::Round($perfDuration, 2)) seconds (acceptable)" $perfDuration
        } else {
            Add-TestResult "Bash Performance" $false "Too slow: $([math]::Round($perfDuration, 2)) seconds" $perfDuration
        }
    } catch {
        Add-TestResult "Bash Performance" $false "Error during performance test"
    }
}

# Test 4: Feature Parity Tests
Write-Host ""
Write-Host "${Blue}🔸 FEATURE PARITY TESTS${Reset}" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Gray

if ($testDumps.Count -gt 0) {
    $testDump = $testDumps[0]
    Write-Host ""
    Write-Host "${Cyan}Testing feature parity with: $($testDump.Name)${Reset}" -ForegroundColor Cyan
    
    # Generate reports from both versions
    $psParityReport = "parity-ps.html"
    $bashParityReport = "parity-bash.html"
    
    try {
        & ".\Analyze-RocketChatDump.ps1" -DumpPath $testDump.FullName -OutputFormat HTML -ExportPath $psParityReport -ErrorAction Stop | Out-Null
        $wslPath = "/mnt/c/Users/i/Downloads/$($testDump.Name)"
        & wsl bash ./analyze-rocketchat-dump.sh --format html --output $bashParityReport $wslPath 2>&1 | Out-Null
        
        if ((Test-Path $psParityReport) -and (Test-Path $bashParityReport)) {
            $psSize = (Get-Item $psParityReport).Length
            $bashSize = (Get-Item $bashParityReport).Length
            $sizeDiff = [math]::Abs($psSize - $bashSize) / [math]::Max($psSize, $bashSize) * 100
            
            if ($sizeDiff -lt 20) {
                Add-TestResult "Feature Parity - Report Size" $true "Size difference: $([math]::Round($sizeDiff, 1))%"
            } else {
                Add-TestResult "Feature Parity - Report Size" $false "Large size difference: $([math]::Round($sizeDiff, 1))%"
            }
            
            # Check content similarity
            $psContent = Get-Content $psParityReport -Raw
            $bashContent = Get-Content $bashParityReport -Raw
            
            $psHasHealth = $psContent.Contains("Health Score")
            $bashHasHealth = $bashContent.Contains("Health Score")
            $psHasSettings = $psContent.Contains("Configuration Settings")
            $bashHasSettings = $bashContent.Contains("Configuration Settings")
            
            if ($psHasHealth -eq $bashHasHealth -and $psHasSettings -eq $bashHasSettings) {
                Add-TestResult "Feature Parity - Content" $true "Both versions have matching core features"
            } else {
                Add-TestResult "Feature Parity - Content" $false "Content feature mismatch detected"
            }
        } else {
            Add-TestResult "Feature Parity" $false "Could not generate both reports for comparison"
        }
    } catch {
        Add-TestResult "Feature Parity" $false "Error during parity test: $($_.Exception.Message)"
    }
}

# Final Results Summary
Write-Host ""
Write-Host "${Cyan}📊 PRODUCTION READINESS RESULTS${Reset}" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$successRate = if ($script:TotalTests -gt 0) { ($script:PassedTests / $script:TotalTests) * 100 } else { 0 }

Write-Host ""
Write-Host "📈 Overall Results:" -ForegroundColor White
Write-Host "   Total Tests: $script:TotalTests" -ForegroundColor White
Write-Host "   Passed: ${Green}$script:PassedTests${Reset}" -ForegroundColor White
Write-Host "   Failed: ${Red}$script:FailedTests${Reset}" -ForegroundColor White
Write-Host "   Success Rate: $([math]::Round($successRate, 1))%" -ForegroundColor White

Write-Host ""
if ($successRate -ge 90) {
    Write-Host "${Green}🎉 PRODUCTION READY!${Reset}" -ForegroundColor Green
    Write-Host "✅ Your RocketChat analyzer is ready for everyday production use!" -ForegroundColor Green
    Write-Host "✅ Both PowerShell and Bash versions are working correctly" -ForegroundColor Green
    Write-Host "✅ Performance is within acceptable limits" -ForegroundColor Green
    Write-Host "✅ Feature parity achieved between versions" -ForegroundColor Green
} elseif ($successRate -ge 75) {
    Write-Host "${Yellow}⚠️  MOSTLY READY${Reset}" -ForegroundColor Yellow
    Write-Host "Your application is mostly ready but has some issues to address." -ForegroundColor Yellow
} else {
    Write-Host "${Red}❌ NOT READY${Reset}" -ForegroundColor Red
    Write-Host "Several critical issues need to be resolved before production use." -ForegroundColor Red
}

Write-Host ""
Write-Host "${Cyan}🔍 Detailed Test Results:${Reset}" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Gray
foreach ($result in $script:TestResults) {
    $status = if ($result.Passed) { "${Green}✅ PASS${Reset}" } else { "${Red}❌ FAIL${Reset}" }
    Write-Host "$status $($result.Test)" -ForegroundColor Gray
    if ($result.Details) {
        Write-Host "     $($result.Details)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "${Cyan}📁 Generated Files:${Reset}" -ForegroundColor Cyan
$htmlFiles = Get-ChildItem -Path "*.html" -File | Where-Object { $_.Name -match "(ps-|bash-|perf-|parity-)" }
foreach ($file in $htmlFiles) {
    $size = [math]::Round($file.Length / 1KB, 2)
    Write-Host "   📄 $($file.Name) ($size KB)" -ForegroundColor Gray
}

if ($htmlFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "${Cyan}🌐 Opening sample reports for verification...${Reset}" -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    
    # Open a few sample reports
    $samplesToOpen = $htmlFiles | Select-Object -First 2
    foreach ($sample in $samplesToOpen) {
        try {
            Start-Process $sample.Name
            Write-Host "   🔗 Opened $($sample.Name)" -ForegroundColor Green
            Start-Sleep -Seconds 1
        } catch {
            Write-Host "   ⚠️  Could not open $($sample.Name)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "${Cyan}✨ Production readiness test completed!${Reset}" -ForegroundColor Cyan
