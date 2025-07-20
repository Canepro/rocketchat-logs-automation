<#
.SYNOPSIS
    Portable Test Runner for RocketChat Log Analyzer - PowerShell Version

.DESCRIPTION
    This script runs comprehensive tests for both bash and PowerShell versions
    Works on Windows PowerShell and PowerShell Core (pwsh)

.PARAMETER UnitOnly
    Run unit tests only

.PARAMETER IntegrationOnly
    Run integration tests only

.PARAMETER BashOnly
    Test bash script only (requires WSL or Git Bash)

.PARAMETER PowerShellOnly
    Test PowerShell script only

.PARAMETER Verbose
    Enable verbose output

.EXAMPLE
    .\run-tests.ps1
    Run all tests

.EXAMPLE
    .\run-tests.ps1 -UnitOnly -PowerShellOnly
    Run only PowerShell unit tests

.EXAMPLE
    .\run-tests.ps1 -Verbose
    Run all tests with verbose output

.NOTES
    Author: Support Engineering Team
    Version: 1.0.0
    Requires: PowerShell 5.1 or later
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$UnitOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$IntegrationOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$BashOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$PowerShellOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$VerboseOutput
)

#Requires -Version 5.1

# Enhanced error handling
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Script locations
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$TestResultsDir = Join-Path $ScriptDir "results"

# Test configuration
$RunUnitTests = -not $IntegrationOnly
$RunIntegrationTests = -not $UnitOnly
$TestBash = -not $PowerShellOnly
$TestPowerShell = -not $BashOnly

# Test counters
$Global:TestsRun = 0
$Global:TestsPassed = 0
$Global:TestsFailed = 0

# Test results collection
$Global:TestResults = @()

# Logging functions
function Write-TestLog {
    param(
        [string]$Level,
        [string]$Message
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Color = switch ($Level) {
        "INFO"  { "Cyan" }
        "PASS"  { "Green" }
        "FAIL"  { "Red" }
        "WARN"  { "Yellow" }
        "DEBUG" { "Blue" }
        default { "White" }
    }
    
    Write-Host "[$Level ] $Message" -ForegroundColor $Color
    
    if ($VerboseOutput -or $Level -ne "DEBUG") {
        $Global:TestResults += @{
            Timestamp = $Timestamp
            Level = $Level
            Message = $Message
        }
    }
}

# Test result functions
function Start-Test {
    param([string]$TestName)
    $Global:TestsRun++
    Write-TestLog "INFO" "Running test: $TestName"
}

function Complete-TestSuccess {
    param([string]$TestName)
    $Global:TestsPassed++
    Write-TestLog "PASS" $TestName
}

function Complete-TestFailure {
    param(
        [string]$TestName,
        [string]$Reason = "Unknown error"
    )
    $Global:TestsFailed++
    Write-TestLog "FAIL" "$TestName - $Reason"
}

# Platform and environment detection
function Get-PlatformInfo {
    $Platform = @{
        OS = [System.Environment]::OSVersion.Platform
        OSVersion = [System.Environment]::OSVersion.VersionString
        PSVersion = $PSVersionTable.PSVersion.ToString()
        PSEdition = $PSVersionTable.PSEdition
        Architecture = [System.Environment]::ProcessorCount
        Is64Bit = [System.Environment]::Is64BitOperatingSystem
    }
    
    return $Platform
}

# Check prerequisites
function Test-Prerequisites {
    Write-TestLog "INFO" "Checking test prerequisites..."
    
    $Platform = Get-PlatformInfo
    Write-TestLog "INFO" "Platform: $($Platform.OS) - $($Platform.OSVersion)"
    Write-TestLog "INFO" "PowerShell: $($Platform.PSVersion) ($($Platform.PSEdition))"
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.1 or later is required. Current version: $($PSVersionTable.PSVersion)"
    }
    
    # Check for JSON handling capability
    try {
        $null = ConvertTo-Json @{test = "value"} -ErrorAction Stop
        $null = ConvertFrom-Json '{"test": "value"}' -ErrorAction Stop
        Write-TestLog "INFO" "JSON processing capabilities verified"
    }
    catch {
        throw "JSON processing capabilities are not available"
    }
    
    # Check bash availability for bash tests
    if ($TestBash) {
        $BashFound = $false
        
        # Check for WSL bash
        if (Get-Command wsl -ErrorAction SilentlyContinue) {
            try {
                $BashVersion = wsl bash --version 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-TestLog "INFO" "WSL bash detected for testing"
                    $BashFound = $true
                }
            }
            catch { }
        }
        
        # Check for Git Bash
        if (-not $BashFound -and (Get-Command bash -ErrorAction SilentlyContinue)) {
            try {
                $BashVersion = bash --version 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-TestLog "INFO" "Git Bash detected for testing"
                    $BashFound = $true
                }
            }
            catch { }
        }
        
        if (-not $BashFound) {
            Write-TestLog "WARN" "Bash not found, skipping bash tests"
            $Script:TestBash = $false
        }
    }
    
    Write-TestLog "INFO" "Prerequisites check completed"
}

# Setup test environment
function Initialize-TestEnvironment {
    Write-TestLog "INFO" "Setting up test environment..."
    
    # Create test results directory
    if (-not (Test-Path $TestResultsDir)) {
        New-Item -Path $TestResultsDir -ItemType Directory -Force | Out-Null
    }
    
    # Create test fixtures if they don't exist
    $FixturesDir = Join-Path $ScriptDir "fixtures"
    if (-not (Test-Path $FixturesDir)) {
        Write-TestLog "INFO" "Creating test fixtures..."
        & (Join-Path $ScriptDir "Create-TestFixtures.ps1")
    }
    
    Write-TestLog "INFO" "Test environment setup completed"
}

# Run PowerShell script tests
function Test-PowerShellScript {
    Write-TestLog "INFO" "Running PowerShell script tests..."
    
    $PSScript = Join-Path $ProjectDir "Analyze-RocketChatDump.ps1"
    
    if (-not (Test-Path $PSScript)) {
        Complete-TestFailure "powershell_script_exists" "PowerShell script not found: $PSScript"
        return
    }
    
    # Test script syntax
    Start-Test "powershell_syntax_check"
    try {
        $null = Get-Command $PSScript -ErrorAction Stop
        Complete-TestSuccess "powershell_syntax_check"
    }
    catch {
        Complete-TestFailure "powershell_syntax_check" "Syntax errors in PowerShell script: $($_.Exception.Message)"
    }
    
    # Test help functionality
    Start-Test "powershell_help_check"
    try {
        $Help = Get-Help $PSScript -ErrorAction Stop
        if ($Help.Name) {
            Complete-TestSuccess "powershell_help_check"
        }
        else {
            Complete-TestFailure "powershell_help_check" "Help content not found"
        }
    }
    catch {
        Complete-TestFailure "powershell_help_check" "PowerShell help check failed: $($_.Exception.Message)"
    }
    
    # Test parameter validation
    Start-Test "powershell_parameter_validation"
    try {
        # This should fail due to missing required parameter
        & $PSScript -ErrorAction SilentlyContinue 2>$null
        if ($LASTEXITCODE -ne 0) {
            Complete-TestSuccess "powershell_parameter_validation"
        }
        else {
            Complete-TestFailure "powershell_parameter_validation" "Script should fail with missing required parameters"
        }
    }
    catch {
        Complete-TestSuccess "powershell_parameter_validation"
    }
    
    # Test with sample data (if integration tests enabled)
    if ($RunIntegrationTests) {
        Start-Test "powershell_sample_analysis"
        $SampleFile = Join-Path $ScriptDir "fixtures" "sample-log.json"
        if (Test-Path $SampleFile) {
            try {
                $Job = Start-Job -ScriptBlock {
                    param($Script, $Sample)
                    & $Script -DumpPath $Sample -OutputFormat JSON
                } -ArgumentList $PSScript, $SampleFile
                
                $Result = Wait-Job $Job -Timeout 30
                $JobOutput = Receive-Job $Job
                Remove-Job $Job -Force
                
                if ($Result) {
                    Complete-TestSuccess "powershell_sample_analysis"
                }
                else {
                    Complete-TestFailure "powershell_sample_analysis" "Sample analysis timed out"
                }
            }
            catch {
                Complete-TestFailure "powershell_sample_analysis" "Sample analysis failed: $($_.Exception.Message)"
            }
        }
        else {
            Complete-TestFailure "powershell_sample_analysis" "Sample file not found"
        }
    }
}

# Run bash script tests (if available)
function Test-BashScript {
    Write-TestLog "INFO" "Running bash script tests..."
    
    $BashScript = Join-Path $ProjectDir "analyze-rocketchat-dump.sh"
    
    if (-not (Test-Path $BashScript)) {
        Complete-TestFailure "bash_script_exists" "Bash script not found: $BashScript"
        return
    }
    
    # Convert Windows path to WSL path if needed
    $BashScriptPath = $BashScript
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        $BashScriptPath = wsl wslpath $BashScript
    }
    
    # Test script syntax
    Start-Test "bash_syntax_check"
    try {
        if (Get-Command wsl -ErrorAction SilentlyContinue) {
            $Result = wsl bash -n $BashScriptPath 2>&1
            if ($LASTEXITCODE -eq 0) {
                Complete-TestSuccess "bash_syntax_check"
            }
            else {
                Complete-TestFailure "bash_syntax_check" "Bash syntax check failed"
            }
        }
        else {
            $Result = bash -n $BashScript 2>&1
            if ($LASTEXITCODE -eq 0) {
                Complete-TestSuccess "bash_syntax_check"
            }
            else {
                Complete-TestFailure "bash_syntax_check" "Bash syntax check failed"
            }
        }
    }
    catch {
        Complete-TestFailure "bash_syntax_check" "Error running bash syntax check: $($_.Exception.Message)"
    }
    
    # Test help functionality
    Start-Test "bash_help_check"
    try {
        if (Get-Command wsl -ErrorAction SilentlyContinue) {
            $Result = wsl timeout 10s bash $BashScriptPath --help 2>&1
        }
        else {
            $Result = & bash $BashScript --help 2>&1
        }
        
        if ($LASTEXITCODE -eq 0) {
            Complete-TestSuccess "bash_help_check"
        }
        else {
            Complete-TestFailure "bash_help_check" "Bash help check failed"
        }
    }
    catch {
        Complete-TestFailure "bash_help_check" "Error running bash help check: $($_.Exception.Message)"
    }
}

# Run unit tests
function Invoke-UnitTests {
    Write-TestLog "INFO" "Running unit tests..."
    
    # Test configuration loading
    Start-Test "config_loading"
    $ConfigFile = Join-Path $ProjectDir "config" "analysis-rules.json"
    if ((Test-Path $ConfigFile)) {
        try {
            $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
            Complete-TestSuccess "config_loading"
        }
        catch {
            Complete-TestFailure "config_loading" "Configuration file contains invalid JSON"
        }
    }
    else {
        Complete-TestFailure "config_loading" "Configuration file missing"
    }
    
    # Test fixture creation
    Start-Test "fixture_creation"
    $FixtureFile = Join-Path $ScriptDir "fixtures" "sample-log.json"
    if (Test-Path $FixtureFile) {
        Complete-TestSuccess "fixture_creation"
    }
    else {
        Complete-TestFailure "fixture_creation" "Test fixtures not properly created"
    }
    
    # Test module structure
    Start-Test "project_structure"
    $RequiredFiles = @(
        "analyze-rocketchat-dump.sh",
        "Analyze-RocketChatDump.ps1",
        "README.md"
    )
    
    $MissingFiles = @()
    foreach ($File in $RequiredFiles) {
        $FilePath = Join-Path $ProjectDir $File
        if (-not (Test-Path $FilePath)) {
            $MissingFiles += $File
        }
    }
    
    if ($MissingFiles.Count -eq 0) {
        Complete-TestSuccess "project_structure"
    }
    else {
        Complete-TestFailure "project_structure" "Missing files: $($MissingFiles -join ', ')"
    }
}

# Generate test report
function New-TestReport {
    Write-TestLog "INFO" "Generating test report..."
    
    $ReportFile = Join-Path $TestResultsDir "test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $Platform = Get-PlatformInfo
    
    $Report = @{
        TestSummary = @{
            Generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Platform = $Platform
            TestsRun = $Global:TestsRun
            TestsPassed = $Global:TestsPassed
            TestsFailed = $Global:TestsFailed
            SuccessRate = if ($Global:TestsRun -gt 0) { [math]::Round(($Global:TestsPassed / $Global:TestsRun) * 100, 2) } else { 0 }
        }
        Configuration = @{
            UnitTests = $RunUnitTests
            IntegrationTests = $RunIntegrationTests
            BashTesting = $TestBash
            PowerShellTesting = $TestPowerShell
            VerboseMode = $VerboseOutput
        }
        Results = $Global:TestResults
    }
    
    $Report | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportFile -Encoding UTF8
    Write-TestLog "INFO" "Test report saved to: $ReportFile"
}

# Print test summary
function Show-TestSummary {
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "         TEST SUMMARY" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "Total Tests Run: $Global:TestsRun"
    Write-Host "Tests Passed:    " -NoNewline
    Write-Host $Global:TestsPassed -ForegroundColor Green
    Write-Host "Tests Failed:    " -NoNewline
    Write-Host $Global:TestsFailed -ForegroundColor Red
    
    if ($Global:TestsFailed -eq 0) {
        Write-Host "Result:          " -NoNewline
        Write-Host "ALL TESTS PASSED" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "Result:          " -NoNewline
        Write-Host "SOME TESTS FAILED" -ForegroundColor Red
        exit 1
    }
}

# Main execution
function Main {
    try {
        Write-Host "RocketChat Log Analyzer Test Suite (PowerShell)" -ForegroundColor Yellow
        Write-Host "================================================" -ForegroundColor Yellow
        
        Test-Prerequisites
        Initialize-TestEnvironment
        
        # Run selected tests
        if ($RunUnitTests) {
            Invoke-UnitTests
        }
        
        if ($TestPowerShell) {
            Test-PowerShellScript
        }
        
        if ($TestBash) {
            Test-BashScript
        }
        
        New-TestReport
        Show-TestSummary
    }
    catch {
        Write-TestLog "FAIL" "Critical error during test execution: $($_.Exception.Message)"
        exit 1
    }
}

# Execute main function
Main
