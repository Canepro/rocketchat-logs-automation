# RocketChat Analyzer - Quick Start Guide

## 🚀 Getting Started

### 1. Basic Analysis
```powershell
# Analyze a RocketChat support dump (Console output)
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump"
```

### 2. Generate Professional HTML Report
```powershell
# Create a professional HTML report
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -OutputFormat HTML -ExportPath "health-report.html"

# Open the report
Start-Process "health-report.html"
```

### 3. Export Data for Analysis
```powershell
# Export to JSON for programmatic use
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -OutputFormat JSON -ExportPath "analysis-data.json"

# Export to CSV for spreadsheet analysis
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -OutputFormat CSV -ExportPath "issues.csv"
```

## 🧹 File Management

### Clean Up Generated Files
```powershell
# Remove all report files
.\Clean-AnalyzerOutputs.ps1 -CleanReports

# Preview what would be deleted
.\Clean-AnalyzerOutputs.ps1 -CleanAll -WhatIf

# Clean everything without prompts
.\Clean-AnalyzerOutputs.ps1 -CleanAll -Force
```

## 📊 Understanding Output

### Health Scores
- **100%**: Excellent, no issues found
- **80-99%**: Good, minor issues present
- **60-79%**: Fair, moderate issues need attention
- **40-59%**: Poor, significant issues require action
- **<40%**: Critical, immediate attention required

### Issue Severity Levels
- **Critical**: System stability or security risks (-25 points)
- **Error**: Functional problems affecting operation (-10 points)
- **Warning**: Configuration issues or improvements needed (-5 points)
- **Info**: General information or recommendations (-1 point)

## 🎯 Real-World Example

Using actual RocketChat 7.8.0 support dump from production:

```powershell
# Full analysis with timestamped report
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$reportPath = "RocketChat-Analysis-$timestamp.html"

.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Users\i\Downloads\7.8.0-support-dump" -OutputFormat HTML -ExportPath $reportPath

Write-Host "Analysis complete! Report saved to: $reportPath" -ForegroundColor Green
Start-Process $reportPath
```

**Example Results:**
- Health Score: 80% (Good)
- Issues Found: 4 warnings
- Components Analyzed: Logs, Settings, Statistics, Apps, Omnichannel
- Apps Flagged: Outdated versions detected

## 🔧 Advanced Usage

### Custom Configuration
```powershell
# Use custom analysis rules
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\dump" -ConfigFile "custom-rules.json"
```

### Verbose Output
```powershell
# Get detailed processing information
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\dump" -Verbose
```

### Filter by Severity
```powershell
# Only show warnings and above
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\dump" -Severity Warning
```

## 🆘 Troubleshooting

### Common Issues
1. **"Dump path does not exist"** - Verify the path to your support dump
2. **"No analysis-rules.json found"** - The script will use defaults (this is normal)
3. **Empty reports** - Check that dump files match expected patterns (*log*.json, *settings*.json, etc.)

### Getting Help
```powershell
# View built-in help
Get-Help .\Analyze-RocketChatDump.ps1 -Full
Get-Help .\Clean-AnalyzerOutputs.ps1 -Examples
```
