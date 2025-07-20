#Requires -Version 5.1

<#
.SYNOPSIS
    Cleanup utility for RocketChat Support Dump Analyzer outputs and temporary files.

.DESCRIPTION
    This utility helps clean up generated reports, temporary files, and test outputs from
    the RocketChat Support Dump Analyzer. It provides options to clean specific file types
    or perform a comprehensive cleanup.

.PARAMETER CleanReports
    Remove all generated report files (HTML, JSON, CSV)

.PARAMETER CleanTests
    Remove test output files and temporary test data

.PARAMETER CleanAll
    Remove all temporary files, reports, and test outputs

.PARAMETER OutputPath
    Specific directory to clean (default: current directory)

.PARAMETER WhatIf
    Show what would be deleted without actually deleting

.PARAMETER Force
    Skip confirmation prompts

.EXAMPLE
    .\Clean-AnalyzerOutputs.ps1 -CleanReports
    Remove all generated report files

.EXAMPLE
    .\Clean-AnalyzerOutputs.ps1 -CleanAll -WhatIf
    Show what would be deleted in a full cleanup

.EXAMPLE
    .\Clean-AnalyzerOutputs.ps1 -OutputPath "C:\Reports" -CleanReports -Force
    Clean reports in specific directory without prompts

.NOTES
    Author: RocketChat Support Engineering Team
    Version: 1.0.0
    Compatible with: PowerShell 5.1+
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(ParameterSetName = "Reports")]
    [switch]$CleanReports,

    [Parameter(ParameterSetName = "Tests")]
    [switch]$CleanTests,

    [Parameter(ParameterSetName = "All")]
    [switch]$CleanAll,

    [Parameter()]
    [string]$OutputPath = (Get-Location).Path,

    [Parameter()]
    [switch]$Force
)

# File patterns to clean
$FilePatterns = @{
    Reports = @(
        "*-report*.html",
        "*-analysis*.json", 
        "*-issues*.csv",
        "*dump*.html",
        "*dump*.json", 
        "*dump*.csv",
        "test-output*.json",
        "test-report*.html"
    )
    Tests = @(
        "test-*.json",
        "test-*.html", 
        "test-*.csv",
        "*-test-*.json",
        "*-test-*.html",
        "*-test-*.csv",
        "temp-*.json",
        "debug-*.log"
    )
    Temporary = @(
        "*.tmp",
        "*.temp",
        "temp_*",
        ".temp*",
        "*_backup_*"
    )
}

function Write-CleanupHeader {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host " RocketChat Analyzer - Cleanup Utility" -ForegroundColor White
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
}

function Write-CleanupStatus {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )
    
    $color = switch ($Type) {
        "Info" { "Cyan" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
    }
    
    $prefix = switch ($Type) {
        "Info" { "[INFO]" }
        "Success" { "[SUCCESS]" }
        "Warning" { "[WARN]" }
        "Error" { "[ERROR]" }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Get-FilesToClean {
    param(
        [string[]]$Patterns,
        [string]$Path
    )
    
    $filesToClean = @()
    
    foreach ($pattern in $Patterns) {
        try {
            $matchingFiles = Get-ChildItem -Path $Path -Filter $pattern -File -ErrorAction SilentlyContinue
            if ($matchingFiles) {
                $filesToClean += $matchingFiles
            }
        }
        catch {
            Write-CleanupStatus "Warning: Could not search for pattern '$pattern': $($_.Exception.Message)" "Warning"
        }
    }
    
    return $filesToClean | Sort-Object Name -Unique
}

function Remove-CleanupFiles {
    param(
        [System.IO.FileInfo[]]$Files,
        [string]$Category,
        [switch]$WhatIf,
        [switch]$Force
    )
    
    if (-not $Files -or $Files.Count -eq 0) {
        Write-CleanupStatus "No $Category files found to clean." "Info"
        return
    }
    
    Write-CleanupStatus "Found $($Files.Count) $Category file(s) to clean:" "Info"
    
    foreach ($file in $Files) {
        $relativePath = $file.FullName.Replace((Get-Location).Path, ".").TrimStart("\")
        $sizeKB = [math]::Round($file.Length / 1KB, 2)
        Write-Host "  • $relativePath ($sizeKB KB)" -ForegroundColor Gray
    }
    
    if ($WhatIf) {
        Write-CleanupStatus "WHAT-IF: Would remove $($Files.Count) $Category files" "Warning"
        return
    }
    
    if (-not $Force) {
        Write-Host ""
        $response = Read-Host "Delete these $($Files.Count) $Category files? (y/N)"
        if ($response -notmatch "^[Yy]") {
            Write-CleanupStatus "Skipping $Category files cleanup." "Info"
            return
        }
    }
    
    $deletedCount = 0
    $totalSize = 0
    
    foreach ($file in $Files) {
        try {
            $totalSize += $file.Length
            Remove-Item -Path $file.FullName -Force
            $deletedCount++
        }
        catch {
            Write-CleanupStatus "Failed to delete '$($file.Name)': $($_.Exception.Message)" "Error"
        }
    }
    
    $totalSizeKB = [math]::Round($totalSize / 1KB, 2)
    Write-CleanupStatus "Successfully deleted $deletedCount $Category files ($totalSizeKB KB freed)" "Success"
}

# Main execution
try {
    Write-CleanupHeader
    
    if (-not (Test-Path $OutputPath)) {
        Write-CleanupStatus "Path does not exist: $OutputPath" "Error"
        exit 1
    }
    
    Write-CleanupStatus "Cleaning path: $OutputPath" "Info"
    
    if ($CleanAll) {
        Write-CleanupStatus "Performing comprehensive cleanup..." "Info"
        
        # Clean all categories
        $allPatterns = $FilePatterns.Reports + $FilePatterns.Tests + $FilePatterns.Temporary
        $allFiles = Get-FilesToClean -Patterns $allPatterns -Path $OutputPath
        Remove-CleanupFiles -Files $allFiles -Category "all output" -WhatIf:$WhatIf -Force:$Force
        
    } elseif ($CleanReports) {
        Write-CleanupStatus "Cleaning report files..." "Info"
        
        $reportFiles = Get-FilesToClean -Patterns $FilePatterns.Reports -Path $OutputPath
        Remove-CleanupFiles -Files $reportFiles -Category "report" -WhatIf:$WhatIf -Force:$Force
        
    } elseif ($CleanTests) {
        Write-CleanupStatus "Cleaning test files..." "Info"
        
        $testFiles = Get-FilesToClean -Patterns $FilePatterns.Tests -Path $OutputPath
        Remove-CleanupFiles -Files $testFiles -Category "test" -WhatIf:$WhatIf -Force:$Force
        
    } else {
        Write-CleanupStatus "No cleanup option specified. Use -CleanReports, -CleanTests, or -CleanAll" "Warning"
        Write-Host ""
        Write-Host "Available options:" -ForegroundColor Yellow
        Write-Host "  -CleanReports  : Remove HTML, JSON, and CSV report files" -ForegroundColor Gray
        Write-Host "  -CleanTests    : Remove test output and temporary files" -ForegroundColor Gray
        Write-Host "  -CleanAll      : Remove all generated files" -ForegroundColor Gray
        Write-Host "  -WhatIf        : Preview what would be deleted" -ForegroundColor Gray
        Write-Host "  -Force         : Skip confirmation prompts" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "  .\Clean-AnalyzerOutputs.ps1 -CleanReports" -ForegroundColor Gray
        Write-Host "  .\Clean-AnalyzerOutputs.ps1 -CleanAll -WhatIf" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host ""
    Write-CleanupStatus "Cleanup completed successfully!" "Success"
    Write-Host ("=" * 60) -ForegroundColor Cyan
    
} catch {
    Write-CleanupStatus "Cleanup failed: $($_.Exception.Message)" "Error"
    exit 1
}
