# Example usage of the RocketChat Log Analyzer

## PowerShell Version Examples

### Basic Usage

#### Analyze a complete support dump directory
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -OutputFormat Console
```

#### Analyze with specific severity filter
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -Severity Error
```

#### Generate HTML report
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -OutputFormat HTML -ExportPath "C:\Reports\rocketchat-analysis.html"
```

#### Generate JSON report for further processing
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -OutputFormat JSON -ExportPath "C:\Reports\analysis.json"
```

#### Analyze a single log file
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-log.json" -OutputFormat Console
```

### Advanced PowerShell Usage

#### Using custom configuration
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -ConfigFile ".\config\custom-rules.json"
```

#### Batch processing multiple dumps
```powershell
$dumps = Get-ChildItem "C:\SupportDumps\" -Directory
foreach ($dump in $dumps) {
    $reportPath = "C:\Reports\$($dump.Name)-analysis.html"
    .\Analyze-RocketChatDump.ps1 -DumpPath $dump.FullName -OutputFormat HTML -ExportPath $reportPath
    Write-Host "Report generated: $reportPath"
}
```

## Bash Version Examples

### Basic Usage

#### Analyze a complete support dump directory
```bash
./analyze-rocketchat-dump.sh /path/to/7.8.0-support-dump
```

#### Analyze with specific severity filter
```bash
./analyze-rocketchat-dump.sh --severity error /path/to/7.8.0-support-dump
```

#### Generate HTML report
```bash
./analyze-rocketchat-dump.sh --format html --output /reports/rocketchat-analysis.html /path/to/dump
```

#### Generate JSON report for further processing
```bash
./analyze-rocketchat-dump.sh --format json --output /reports/analysis.json /path/to/dump
```

#### Analyze a single log file
```bash
./analyze-rocketchat-dump.sh /path/to/7.8.0-log.json
```

### Advanced Bash Usage

#### Using custom configuration
```bash
./analyze-rocketchat-dump.sh --config ./config/custom-rules.json /path/to/dump
```

#### Verbose output for debugging
```bash
./analyze-rocketchat-dump.sh --verbose --severity warning /path/to/dump
```

#### Batch processing multiple dumps
```bash
#!/bin/bash
for dump_dir in /path/to/support-dumps/*/; do
    dump_name=$(basename "$dump_dir")
    report_path="/reports/${dump_name}-analysis.html"
    ./analyze-rocketchat-dump.sh --format html --output "$report_path" "$dump_dir"
    echo "Report generated: $report_path"
done
```

#### Quick health check (errors only)
```bash
./analyze-rocketchat-dump.sh --severity error /path/to/dump | grep -E "(ERROR|CRITICAL)"
```

## Cross-Platform Scenarios

### Windows with WSL
```bash
# Using bash version in WSL
./analyze-rocketchat-dump.sh /mnt/c/Downloads/7.8.0-support-dump --format html --output /mnt/c/Reports/analysis.html

# Using PowerShell from WSL
pwsh.exe -File "./Analyze-RocketChatDump.ps1" -DumpPath "C:\Downloads\7.8.0-support-dump"
```

### Linux Server Automation
```bash
#!/bin/bash
# Automated daily analysis
DUMP_DIR="/var/rocketchat/support-dumps"
REPORT_DIR="/var/www/html/reports"
DATE=$(date +%Y%m%d)

for dump in "$DUMP_DIR"/*.tar.gz; do
    # Extract dump
    temp_dir=$(mktemp -d)
    tar -xzf "$dump" -C "$temp_dir"
    
    # Analyze
    dump_name=$(basename "$dump" .tar.gz)
    ./analyze-rocketchat-dump.sh --format html --output "$REPORT_DIR/${dump_name}-${DATE}.html" "$temp_dir"
    
    # Cleanup
    rm -rf "$temp_dir"
done
```

### macOS with Homebrew
```bash
# Install dependencies
brew install jq

# Run analysis
./analyze-rocketchat-dump.sh --verbose ~/Downloads/rocketchat-dump
```

## Integration Examples

### CI/CD Pipeline Integration
```bash
# Jenkins/GitLab CI script
./analyze-rocketchat-dump.sh --format json --output analysis.json /path/to/dump

# Check if critical issues found
if grep -q '"critical"' analysis.json; then
    echo "Critical issues found in RocketChat dump"
    exit 1
fi
```

### Automated Monitoring
```bash
#!/bin/bash
# Monitor script for cron
./analyze-rocketchat-dump.sh --severity error /path/to/latest/dump > /tmp/rc_issues.log

if [ -s /tmp/rc_issues.log ]; then
    mail -s "RocketChat Issues Detected" admin@company.com < /tmp/rc_issues.log
fi
```

### PowerShell with Task Scheduler
```powershell
# Scheduled task script
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$reportPath = "C:\Reports\daily-health-$timestamp.html"

.\Analyze-RocketChatDump.ps1 -DumpPath "C:\RocketChat\latest-dump" -OutputFormat HTML -ExportPath $reportPath

# Email report if issues found
$report = Get-Content $reportPath -Raw
if ($report -match "score-poor|Critical|Error") {
    Send-MailMessage -To "admin@company.com" -Subject "RocketChat Health Issues" -Body $report -BodyAsHtml
}
```

## Expected File Structure

The script expects the following files in a support dump:
- `*-log.json` - System logs
- `*-settings.json` - RocketChat configuration settings
- `*-server-statistics.json` - Server performance statistics
- `*-omnichannel-settings.json` - Omnichannel configuration (optional)
- `*-apps-installed.json` - Installed apps and integrations (optional)

## Output Formats

### Console Output
- Colored output with health scores
- Summary of issues by severity
- Top error patterns
- Performance metrics
- Security analysis
- Recommendations

### JSON Output
Complete analysis data in structured format for integration with other tools.

### CSV Output
Tabular format suitable for spreadsheet analysis, containing all identified issues.

### HTML Output
Professional report with:
- Executive summary
- Detailed analysis sections
- Charts and visual indicators
- Responsive design for web viewing

## Common Support Scenarios

### High Memory Usage Investigation
```powershell
# Focus on performance issues
.\Analyze-RocketChatDump.ps1 -DumpPath $dumpPath -Severity Warning | Select-String "memory|performance"
```

### Security Audit
```powershell
# Generate full report with security focus
.\Analyze-RocketChatDump.ps1 -DumpPath $dumpPath -OutputFormat HTML -ExportPath "security-audit.html"
```

### Error Pattern Analysis
```powershell
# Export to JSON for detailed pattern analysis
.\Analyze-RocketChatDump.ps1 -DumpPath $dumpPath -OutputFormat JSON -ExportPath "error-analysis.json"
```
