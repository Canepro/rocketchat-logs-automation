#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verifies the HTML structure to ensure sections are properly closed and not nested.

.DESCRIPTION
    This script analyzes the generated HTML report to verify:
    - Configuration Settings section is properly closed
    - Recommendations section appears as a sibling, not nested
    - Analysis Summary section appears as a sibling, not nested
    - All section containers are properly structured
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ReportPath
)

# Find the most recent HTML report if not specified
if (-not $ReportPath) {
    $ReportPath = Get-ChildItem -Path "." -Filter "RocketChat-Analysis-Report_*.html" | 
                  Sort-Object LastWriteTime -Descending | 
                  Select-Object -First 1 -ExpandProperty FullName
}

if (-not $ReportPath -or -not (Test-Path $ReportPath)) {
    Write-Error "No HTML report found. Please specify -ReportPath or ensure a report exists."
    exit 1
}

Write-Host "🔍 Analyzing HTML Structure: $ReportPath" -ForegroundColor Cyan
Write-Host "=" * 60

# Read the HTML content
$htmlContent = Get-Content -Path $ReportPath -Raw

# Check for section structure
Write-Host "`n📊 Section Analysis:" -ForegroundColor Green

# Count total sections
$sectionCount = ([regex]::Matches($htmlContent, '<div class="section')).Count
Write-Host "  • Total sections found: $sectionCount" -ForegroundColor White

# Check specific sections
$configSection = $htmlContent -match 'Configuration Settings.*?</div>'
$configSectionMatches = ([regex]::Matches($htmlContent, '⚙️ Configuration Settings')).Count
Write-Host "  • Configuration Settings sections: $configSectionMatches" -ForegroundColor $(if ($configSectionMatches -eq 1) { "Green" } else { "Red" })

$recommendationsMatches = ([regex]::Matches($htmlContent, '💡 Recommendations & Action Items')).Count
Write-Host "  • Recommendations sections: $recommendationsMatches" -ForegroundColor $(if ($recommendationsMatches -eq 1) { "Green" } else { "Red" })

$summaryMatches = ([regex]::Matches($htmlContent, 'Analysis Summary & Technical Details')).Count
Write-Host "  • Analysis Summary sections: $summaryMatches" -ForegroundColor $(if ($summaryMatches -eq 1) { "Green" } else { "Red" })

# Check for proper section closures
Write-Host "`n🔧 Structure Validation:" -ForegroundColor Green

# Look for unclosed here-strings or malformed sections
$unclosedHereStrings = ([regex]::Matches($htmlContent, '@"[^"]*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
Write-Host "  • Unclosed here-strings: $unclosedHereStrings" -ForegroundColor $(if ($unclosedHereStrings -eq 0) { "Green" } else { "Red" })

# Check div balance
$openDivs = ([regex]::Matches($htmlContent, '<div[^>]*>')).Count
$closeDivs = ([regex]::Matches($htmlContent, '</div>')).Count
$divBalance = $openDivs - $closeDivs
Write-Host "  • Div balance (open - close): $divBalance" -ForegroundColor $(if ($divBalance -eq 0) { "Green" } else { "Yellow" })
Write-Host "    - Open divs: $openDivs" -ForegroundColor Gray
Write-Host "    - Close divs: $closeDivs" -ForegroundColor Gray

# Check for nesting issues by looking at section order
Write-Host "`n🎯 Nesting Analysis:" -ForegroundColor Green

# Extract the order of major sections
$majorSections = @()
if ($htmlContent -match '⚙️ Configuration Settings') { $majorSections += "Configuration Settings" }
if ($htmlContent -match '💡 Recommendations & Action Items') { $majorSections += "Recommendations" }
if ($htmlContent -match 'Analysis Summary & Technical Details') { $majorSections += "Analysis Summary" }

Write-Host "  • Section order detected:" -ForegroundColor White
foreach ($section in $majorSections) {
    Write-Host "    - $section" -ForegroundColor Cyan
}

# Check if sections appear to be properly separated (not nested)
$configToRecommendations = $htmlContent.IndexOf('💡 Recommendations & Action Items') - $htmlContent.IndexOf('⚙️ Configuration Settings')
$recommendationsToSummary = if ($htmlContent.Contains('Analysis Summary & Technical Details')) {
    $htmlContent.IndexOf('Analysis Summary & Technical Details') - $htmlContent.IndexOf('💡 Recommendations & Action Items')
} else { -1 }

Write-Host "`n  • Section separation check:" -ForegroundColor White
if ($configToRecommendations -gt 500) {
    Write-Host "    ✅ Configuration → Recommendations: Properly separated" -ForegroundColor Green
} else {
    Write-Host "    ❌ Configuration → Recommendations: May be nested ($configToRecommendations chars)" -ForegroundColor Red
}

if ($recommendationsToSummary -gt 200) {
    Write-Host "    ✅ Recommendations → Summary: Properly separated" -ForegroundColor Green
} elseif ($recommendationsToSummary -eq -1) {
    Write-Host "    ℹ️  Analysis Summary section not found" -ForegroundColor Yellow
} else {
    Write-Host "    ❌ Recommendations → Summary: May be nested ($recommendationsToSummary chars)" -ForegroundColor Red
}

# File size analysis
$fileSize = (Get-Item $ReportPath).Length
$fileSizeKB = [math]::Round($fileSize / 1024, 2)
Write-Host "`n📁 File Analysis:" -ForegroundColor Green
Write-Host "  • File size: $fileSizeKB KB" -ForegroundColor White
Write-Host "  • Status: $(if ($fileSizeKB -lt 50) { "⚠️  Unusually small" } elseif ($fileSizeKB -gt 500) { "⚠️  Unusually large" } else { "✅ Normal size" })" -ForegroundColor $(if ($fileSizeKB -lt 50 -or $fileSizeKB -gt 500) { "Yellow" } else { "Green" })

Write-Host "`n" -NoNewline
Write-Host "=" * 60
Write-Host "Analysis complete! Open the report in a browser to verify visual structure." -ForegroundColor Cyan
