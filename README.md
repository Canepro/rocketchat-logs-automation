# RocketChat Support Dump Analyzer

A comprehensive automation tool for analyzing RocketChat support dumps and system logs. Available in both **PowerShell** and **Bash** versions with **complete feature parity** for cross-platform support.

**✅ Production Ready** - Successfully tested with real RocketChat 7.8.0 support dumps (1021+ settings)  
**🚀 v1.4.0** - Enhanced Configuration Settings analysis with interactive HTML reports  
**🎯 Complete Parity** - Both versions now offer identical functionality and output

## 🚀 Quick Start

### **PowerShell Version** (Windows)
```powershell
# Basic analysis with HTML report
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Users\YourName\Downloads\7.8.0-support-dump" -OutputFormat HTML

# Quick console analysis
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Users\YourName\Downloads\7.8.0-support-dump"

# Export to specific location
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\dump" -OutputFormat HTML -ExportPath "C:\Reports\analysis.html"
```

### **Bash Version** (Linux/macOS/WSL)
```bash
# Basic analysis with HTML report
bash analyze-rocketchat-dump.sh --format html --output report.html /path/to/7.8.0-support-dump

# Quick console analysis
bash analyze-rocketchat-dump.sh /path/to/7.8.0-support-dump

# Windows users with WSL - use mount paths
bash analyze-rocketchat-dump.sh --format html /mnt/c/Users/YourName/Downloads/7.8.0-support-dump
```

## 📚 Documentation

### **Essential Reading**
- **🚀 [Usage Guide](USAGE.md)** - Step-by-step instructions for all platforms
- **📋 [Release Notes](RELEASE_NOTES.md)** - Complete version history and features
- **📝 [Changelog](CHANGELOG.md)** - Technical changes and improvements
- **💻 [Examples](examples/)** - Usage examples and real-world scenarios

## ✨ Features

## ✨ Features

### 🎯 **v1.4.0 - Enhanced Configuration Settings Analysis**
- **Complete Feature Parity** between PowerShell and Bash versions
- **1000+ Settings Support** - Handles large-scale RocketChat configurations  
- **Expandable Categories** - SAML, LDAP, API, Accounts, Email, FileUpload, Security, Performance
- **HTML Content Escaping** - Safe handling of XML templates and complex configurations
- **Real-time Filtering** - Interactive category browsing with collapsible sections

### 📊 **Professional HTML Reports**
- **Modern responsive design** with gradient backgrounds and professional styling
- **Interactive collapsible sections** for detailed exploration
- **Interactive Log Analysis v1.4.0** with expandable log entries and real-time filtering
- **JavaScript-powered severity filtering** (Critical, Error, Warning, Info) with real-time counts
- **Enhanced Configuration Settings** with expandable/collapsible categories
- **Apps & Integrations v1.5.0** with interactive cards and status indicators
- **Executive summary** with immediate health assessment and recommendations
- **Visual health indicators** with color-coded status badges (🟢🟡🔴)
- **Mobile-friendly** responsive layout for viewing on any device
- **Cross-platform auto-opening** functionality for Windows, Linux, and macOS

### 🏥 **Advanced Health Scoring System**
- **Overall system health percentage** with visual status indicators
- **Component-specific scoring** for Logs, Settings, Performance, and Security
- **Issue impact weighting** (Critical: -25pts, Error: -10pts, Warning: -5pts, Info: -1pt)
- **Automated recommendations** based on health score and identified issues
- **Trend analysis** and performance insights

### 🔍 **Comprehensive Analysis**
- **100% Cross-Platform Feature Parity**: Both PowerShell and Bash versions now provide identical functionality
- **Interactive Log Analysis v1.4.0**: Available in both PowerShell and Bash versions with expandable entries
- **Enhanced Configuration Settings**: Smart categorization with expandable/collapsible sections
- **Apps & Integrations v1.5.0**: Real app data parsing with interactive cards and status indicators
- **Multiple Data Sources**: Analyzes logs, settings, statistics, Omnichannel configuration, and installed apps
- **Multiple Output Formats**: Console, JSON, CSV, and professional HTML reports
- **Pattern Recognition**: Automatically detects error patterns and trends
- **Security Analysis**: Reviews security settings and identifies potential vulnerabilities
- **Performance Insights**: Analyzes memory usage, user load, and system performance
- **Configurable Rules**: Customizable analysis rules and thresholds
- **Cross-Platform**: Works on Windows, macOS, and Linux

## 📊 Feature Parity Matrix

| Feature | PowerShell Version | Bash Version |
|---------|-------------------|--------------|
| Interactive Log Analysis v1.4.0 | ✅ | ✅ |
| Expandable Configuration Settings | ✅ | ✅ |
| Apps & Integrations Analysis v1.5.0 | ✅ | ✅ |
| Dynamic Recommendations | ✅ | ✅ |
| Analysis Summary & Technical Details | ✅ | ✅ |
| Auto-opening HTML Reports | ✅ | ✅ |
| Cross-platform Support | ✅ | ✅ |
| JSON Export | ✅ | ✅ |
| CSV Export | ✅ | ✅ |
| Health Score Calculation | ✅ | ✅ |
| Real-time Log Filtering | ✅ | ✅ |
| Settings Categorization | ✅ | ✅ |
| **FEATURE PARITY** | **100%** | **100%** |

## 📋 Requirements

### PowerShell Version
- PowerShell 5.1 or later (PowerShell Core 7+ recommended)
- Windows, macOS, or Linux
- Read access to RocketChat support dump files

### Bash Version
- Bash 4.0 or later
- `jq` for JSON processing
- Standard Unix tools: `grep`, `awk`, `sed`, `wc`, `sort`
- Linux, macOS, or WSL on Windows

## 🛠️ Installation

### PowerShell Version
1. Clone or download this repository
2. Ensure PowerShell execution policy allows script execution:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. Navigate to the project directory
4. Test the setup: `.\Test-Analyzer.ps1`
5. You're ready to analyze RocketChat dumps!

### Bash Version
1. Clone or download this repository
2. Install required dependencies:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq grep gawk sed coreutils
   
   # CentOS/RHEL
   sudo yum install jq grep gawk sed coreutils
   
   # macOS
   brew install jq
   ```
3. Make scripts executable:
   ```bash
   chmod +x analyze-rocketchat-dump.sh test-analyzer.sh
   ```
4. Test the setup: `./test-analyzer.sh`
5. You're ready to analyze RocketChat dumps!

## 📊 Quick Start

### PowerShell Version

#### Basic Analysis
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump"
```

#### Generate Professional HTML Report
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -OutputFormat HTML -ExportPath "report.html"
```

#### View HTML Report
```powershell
# Open the HTML report in default browser
Start-Process "report.html"

# Or specify a browser explicitly
Start-Process "chrome.exe" "report.html"
Start-Process "msedge.exe" "report.html"
Start-Process "firefox.exe" "report.html"
```

The HTML report features:
- 🎨 **Modern gradient design** with professional styling
- 📊 **Interactive health dashboard** with visual indicators
- 🔧 **Collapsible sections** for detailed exploration
- 📱 **Responsive design** for mobile and desktop viewing
- 🎯 **Executive summary** for quick decision making
- 📈 **Component health scoring** with color-coded status
- 💡 **Actionable recommendations** with prioritized next steps

#### Filter by Severity
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -Severity Error
```

### Bash Version

#### Basic Analysis
```bash
./analyze-rocketchat-dump.sh /path/to/7.8.0-support-dump
```

#### Generate HTML Report
```bash
./analyze-rocketchat-dump.sh --format html --output report.html /path/to/dump
```

#### View HTML Report
```bash
# On Linux/macOS - open in default browser
xdg-open report.html    # Linux
open report.html        # macOS

# On Windows via WSL - open in Windows browser
explorer.exe report.html

# Or use PowerShell to open
powershell.exe "Start-Process report.html"
```

#### Filter by Severity
```bash
./analyze-rocketchat-dump.sh --severity error /path/to/dump
```

#### Windows Users (via WSL)
```batch
REM Use the Windows wrapper batch file
analyze-bash.bat C:\Downloads\7.8.0-support-dump

REM Or use WSL directly
wsl bash ./analyze-rocketchat-dump.sh /mnt/c/Downloads/7.8.0-support-dump

REM For paths with spaces, use quotes
wsl bash ./analyze-rocketchat-dump.sh "/mnt/c/Users/i/Downloads/7.8.0-support-dump _1_"
```

## 📊 HTML Reports & Health Scoring

### 🎨 Professional HTML Reports

The tool generates **production-ready HTML reports** with modern design and interactive features:

#### Visual Features
- **Modern gradient design** with professional blue theme
- **Responsive layout** that adapts to mobile, tablet, and desktop screens
- **Interactive hover effects** and smooth CSS animations
- **Glass-morphism styling** with backdrop blur effects
- **Professional typography** using Segoe UI font family

#### Health Dashboard
- **Executive summary** with immediate system health assessment
- **Visual health indicators** using color-coded badges:
  - 🟢 **EXCELLENT** (90-100%): System performing optimally
  - 🟡 **GOOD** (70-89%): Minor improvements recommended
  - 🔴 **CRITICAL** (<70%): Immediate attention required

#### Interactive Elements
- **Collapsible sections** - Click section headers to expand/collapse content
- **Detailed issue cards** with severity icons and timestamps
- **Component health breakdown** with individual scoring
- **Actionable recommendations** with prioritized next steps

#### 🆕 Interactive Log Analysis v1.4.0
- **Expandable log entries** - Click to view full log details with context
- **JavaScript-powered severity filtering** - Filter by Critical, Error, Warning, Info
- **Real-time count updates** - Dynamic counters that update as you filter
- **Consistent display logic** - Accurate counts between summary and detailed views
- **Cross-version compatibility** - Works with RocketChat 7.2.0, 7.6.1, 7.8.0+
- **Smart fallback** - Shows sample entries when no real errors are found
- **100% Cross-platform support** - Available in both PowerShell and Bash versions with identical functionality

### 🏥 Health Scoring Algorithm

The health scoring system provides comprehensive assessment across multiple components:

#### Scoring Methodology
```
Base Score: 100%
- Critical Issues: -25 points each
- Error Issues: -10 points each  
- Warning Issues: -5 points each
- Info Issues: -1 point each
Minimum Score: 0%
```

#### Component Scores
- **Logs**: Based on error frequency and patterns
- **Settings**: Configuration compliance and best practices
- **Performance**: Memory usage, CPU load, and response times
- **Security**: Authentication, access controls, and vulnerabilities

#### Example Health Report
```
📊 HEALTH OVERVIEW
Overall Health Score: 75%
Issues Summary:
  • Critical: 0
  • Error: 2
  • Warning: 1
  • Info: 0

Component Health:
  • Security: 100% 🟢
  • Performance: 100% 🟢
  • Settings: 100% 🟢
  • Logs: 85% 🟡
```

### 💡 Automated Recommendations

Based on the health score and identified issues, the system provides:

- **Priority actions** for immediate attention
- **Next steps** with time-bound recommendations
- **Security improvements** when issues are detected
- **Performance optimization** suggestions
- **Maintenance recommendations** for long-term health

### 📱 Cross-Platform Viewing

HTML reports work seamlessly across platforms:

```powershell
# Windows
Start-Process "report.html"                    # Default browser
Start-Process "msedge.exe" "report.html"      # Microsoft Edge
Start-Process "chrome.exe" "report.html"      # Google Chrome

# macOS
open report.html                               # Default browser
open -a "Google Chrome" report.html           # Chrome
open -a Safari report.html                    # Safari

# Linux
xdg-open report.html                          # Default browser
firefox report.html                           # Firefox
google-chrome report.html                     # Chrome
```

## 🧪 Testing the Installation

### Test Without Real Data
Both versions include test scripts to verify your installation:

```powershell
# PowerShell version
.\Test-Analyzer.ps1
```

```bash
# Bash version
./test-analyzer.sh

# Windows users via WSL
wsl bash ./test-analyzer.sh
```

### Test With Real Data
Once you have a RocketChat support dump, test with actual data:

```powershell
# PowerShell - replace with your actual dump path
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\your-actual-dump"
```

```bash
# Bash - replace with your actual dump path
./analyze-rocketchat-dump.sh /path/to/your-actual-dump

# Windows users via WSL
wsl bash ./analyze-rocketchat-dump.sh /mnt/c/Downloads/your-actual-dump
```

**Note**: If you see `[ERROR] Dump path does not exist` messages, this is normal behavior when testing with non-existent paths. The error handling is working correctly!

## 📊 Complete Workflow Examples

### Generate and View Professional HTML Reports

#### Example 1: Quick Analysis with Auto-Open Report
```bash
# Bash version - Generate report and open automatically
./analyze-rocketchat-dump.sh --format html --output "rocketchat-analysis-$(date +%Y%m%d).html" /path/to/dump && \
xdg-open "rocketchat-analysis-$(date +%Y%m%d).html"  # Linux
# open "rocketchat-analysis-$(date +%Y%m%d).html"     # macOS
```

```powershell
# PowerShell version - Generate report and open automatically
$reportName = "rocketchat-analysis-$(Get-Date -Format 'yyyyMMdd-HHmm').html"
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -OutputFormat HTML -ExportPath $reportName
Start-Process $reportName
```

#### Example 2: Comprehensive Analysis for Presentations
```bash
# Generate detailed report with timestamp
./analyze-rocketchat-dump.sh --format html --output "RocketChat-Health-Report-$(date +%Y-%m-%d).html" --verbose /path/to/dump

# Open for viewing
xdg-open "RocketChat-Health-Report-$(date +%Y-%m-%d).html"  # Linux
```

```powershell
# PowerShell - Generate timestamped report
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$reportPath = "RocketChat-Health-Report-$timestamp.html"
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -OutputFormat HTML -ExportPath $reportPath -Verbose
Write-Host "Report generated: $reportPath" -ForegroundColor Green
Start-Process $reportPath
```

## 🧹 Cleanup Utility

The `Clean-AnalyzerOutputs.ps1` utility helps you manage generated reports and temporary files:

### Basic Cleanup Commands

```powershell
# Clean all generated report files (HTML, JSON, CSV)
.\Clean-AnalyzerOutputs.ps1 -CleanReports

# Clean test outputs and temporary files
.\Clean-AnalyzerOutputs.ps1 -CleanTests

# Clean everything (reports, tests, temporary files)
.\Clean-AnalyzerOutputs.ps1 -CleanAll

# Preview what would be deleted without actually deleting
.\Clean-AnalyzerOutputs.ps1 -CleanAll -WhatIf

# Clean without confirmation prompts
.\Clean-AnalyzerOutputs.ps1 -CleanReports -Force
```

### Advanced Usage

```powershell
# Clean specific directory
.\Clean-AnalyzerOutputs.ps1 -CleanReports -OutputPath "C:\Reports" -Force

# See what files would be deleted
.\Clean-AnalyzerOutputs.ps1 -CleanAll -WhatIf
```

### File Types Cleaned

- **Reports**: `*-report*.html`, `*-analysis*.json`, `*-issues*.csv`, `*dump*.html/json/csv`
- **Tests**: `test-*.json/html/csv`, `*-test-*.json/html/csv`, `temp-*.json`, `debug-*.log`
- **Temporary**: `*.tmp`, `*.temp`, `temp_*`, `.temp*`, `*_backup_*`

The cleanup utility provides:
- 🔍 **Safe preview** with `-WhatIf` parameter
- 📊 **Size reporting** showing space freed
- ⚡ **Selective cleanup** by file category
- 🛡️ **Confirmation prompts** (unless `-Force` is used)

## 📁 Project Structure

```
Rocketchat_Logs_Automation/
├── Analyze-RocketChatDump.ps1    # Main PowerShell analysis script
├── analyze-rocketchat-dump.sh    # Main Bash analysis script
├── Clean-AnalyzerOutputs.ps1     # Cleanup utility for generated files
├── analyze-bash.bat              # Windows wrapper for bash version (via WSL)
├── Test-Analyzer.ps1             # PowerShell test script
├── test-analyzer.sh              # Bash test script
├── modules/                       # PowerShell modules
│   ├── RocketChatLogParser.psm1   # Log parsing functions
│   ├── RocketChatAnalyzer.psm1    # Analysis and pattern detection
│   └── ReportGenerator.psm1       # Report generation functions
├── config/                        # Configuration files (shared)
│   └── analysis-rules.json        # Analysis rules and thresholds
├── examples/                      # Usage examples and documentation
│   └── usage-examples.md          # Detailed usage examples
├── tests/                         # Test fixtures and test scripts
│   ├── fixtures/                  # Sample test data
│   ├── results/                   # Test output results
│   └── *.ps1, *.sh               # Test scripts
├── QUICK-START.md                 # Quick start guide with examples
├── COMPARISON.md                  # PowerShell vs Bash comparison
└── README.md                      # This file
```

## 🔧 Parameters

### PowerShell Version

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DumpPath` | String | Yes | Path to RocketChat support dump directory or file |
| `OutputFormat` | String | No | Output format: Console, JSON, CSV, HTML (default: Console) |
| `Severity` | String | No | Minimum severity level: Info, Warning, Error, Critical (default: Info) |
| `ExportPath` | String | No | Path for exported reports |
| `ConfigFile` | String | No | Custom configuration file path |

### Bash Version

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `DUMP_PATH` | String | Yes | Path to RocketChat support dump directory or file |
| `--format, -f` | String | No | Output format: console, json, csv, html (default: console) |
| `--severity, -s` | String | No | Minimum severity level: info, warning, error, critical (default: info) |
| `--output, -o` | String | No | Path for exported reports |
| `--config, -c` | String | No | Custom configuration file path |
| `--verbose, -v` | Flag | No | Enable verbose output |

## 📈 Analysis Components

### 1. Log Analysis
- Error and warning detection with interactive filtering
- **Interactive Log Analysis v1.4.0** (PowerShell): Expandable log entries with JavaScript-powered severity filtering
- Pattern recognition and frequency analysis
- Timeline analysis with real-time count updates
- Performance issue identification

### 2. Settings Analysis
- Security configuration review
- Performance settings validation
- Best practices compliance
- Configuration drift detection

### 3. Statistics Analysis
- Server performance metrics
- Memory and CPU usage analysis
- User activity patterns
- Message volume analysis

### 4. Security Analysis
- Authentication settings review
- Permission configuration audit
- Security score calculation
- Vulnerability identification

### 5. Health Scoring
- Overall system health percentage
- Component-specific scores
- Issue impact weighting
- Trend analysis

## 📊 Report Formats

### Console Output
- Color-coded severity levels
- Real-time analysis progress
- Summary statistics
- Quick issue overview

### JSON Export
- Complete structured data
- Integration-ready format
- Detailed metadata
- Programmatic access

### CSV Export
- Spreadsheet-compatible format
- Issue tracking and filtering
- Trend analysis support
- Data manipulation ready

### HTML Report
- Professional presentation format
- Visual charts and indicators
- Executive summary
- Detailed technical sections

## ⚙️ Configuration

The tool uses a JSON configuration file (`config/analysis-rules.json`) to define:

- **Error Patterns**: Regular expressions for identifying issues
- **Performance Thresholds**: Memory, CPU, and response time limits
- **Security Settings**: Required and recommended configuration values
- **Analysis Rules**: Severity weights and processing options

### Custom Configuration Example
```json
{
  "logPatterns": {
    "error": ["error", "exception", "failed", "timeout"],
    "warning": ["warn", "deprecated", "slow"],
    "security": ["auth", "unauthorized", "permission"]
  },
  "performanceThresholds": {
    "memoryUsageMB": 2048,
    "cpuUsagePercent": 90,
    "responseTime": 5000
  }
}
```

## 🎯 Common Use Cases

### Support Ticket Investigation
Quickly identify the root cause of user-reported issues by analyzing error patterns and system metrics.

### Health Check Automation
Regular automated analysis of RocketChat instances to proactively identify potential issues.

### Security Audits
Comprehensive review of security settings and identification of potential vulnerabilities.

### Performance Optimization
Analysis of system performance metrics to identify bottlenecks and optimization opportunities.

### Compliance Reporting
Generate detailed reports for compliance audits and documentation requirements.

## 🔍 Troubleshooting

### PowerShell Common Issues

1. **"Execution Policy" Error**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Module Import Errors**
   - Ensure all module files are present in the `modules/` directory
   - Check file permissions

3. **JSON Parsing Errors**
   - Verify dump file integrity
   - Check for non-standard JSON formatting

### Bash Common Issues

1. **Permission Denied**
   ```bash
   # On Linux/macOS/WSL
   chmod +x analyze-rocketchat-dump.sh test-analyzer.sh
   
   # On Windows (use WSL or Git Bash)
   # Files should already be executable when downloaded/cloned
   ```

2. **Missing Dependencies**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq
   
   # macOS
   brew install jq
   
   # CentOS/RHEL
   sudo yum install jq
   ```

3. **jq Not Found**
   - Install jq using your system's package manager
   - Verify installation: `jq --version`

4. **Syntax Errors on Windows**
   - Use WSL, Git Bash, or a proper Unix environment
   - Ensure line endings are LF (not CRLF)
   - PowerShell doesn't support bash syntax

### Cross-Platform Issues

1. **WSL Path Issues**
   - Use `/mnt/c/path` format for Windows paths in WSL
   - Ensure line endings are LF not CRLF
   - **For paths with spaces, always use quotes**: `"/mnt/c/Users/Name/folder with spaces"`

2. **File Not Found**
   - Check path separators (\ vs /)
   - Verify file permissions and access
   - **Quote paths containing spaces or special characters**

### Getting Help

If you encounter issues:
1. Check the examples in `examples/usage-examples.md`
2. Review the comparison guide in `COMPARISON.md`
3. Verify your environment:
   - PowerShell: `$PSVersionTable`
   - Bash: `bash --version && jq --version`
4. Test with a minimal dump file first
5. Check the configuration file syntax

## 🤝 Contributing

This tool is designed for RocketChat support teams. To contribute:

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request with detailed description

## 🆕 Recent Updates (July 2025)

### ✅ Production Testing Completed
- **Successfully tested** with real RocketChat 7.8.0 support dumps
- **Verified functionality** across all output formats (Console, JSON, CSV, HTML)
- **Confirmed issue detection** with 4 warning-level issues found in production data

### 🔧 Latest Enhancements
- **Enhanced pipeline control** with improved error handling and debug output
- **Fixed JSON serialization** issues in PowerShell modules (hashtable conversion)
- **Comprehensive function documentation** with detailed help text and examples
- **Advanced analysis capabilities** for Omnichannel, Apps, and Security settings

### 🧹 New Cleanup Utility
- **`Clean-AnalyzerOutputs.ps1`** utility for managing generated files
- **Selective cleanup** by file type (reports, tests, temporary files)
- **Safe preview mode** with `-WhatIf` parameter
- **Size reporting** showing disk space freed

### 🐛 Bug Fixes
- Resolved PowerShell pipeline control issues
- Fixed JSON export hashtable serialization errors
- Enhanced error handling throughout all modules
- Improved file detection patterns for real support dumps

### 📊 Verified Components
- ✅ Log Analysis: Error and pattern detection working
- ✅ Settings Analysis: Security and performance validation
- ✅ Statistics Analysis: Server metrics and resource usage
- ✅ Apps Analysis: Version checking and status validation
- ✅ Omnichannel Analysis: Configuration review
- ✅ All Export Formats: Console, JSON, CSV, and HTML reports

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Related Resources

- [RocketChat Documentation](https://docs.rocket.chat/)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [JSON Format Specification](https://www.json.org/)

## 📞 Support

For questions or issues related to this tool:
- Check the troubleshooting section above
- Review usage examples
- Contact your RocketChat support team

---

**Version**: 1.4.0  
**Last Updated**: 2025-07-21  
**Compatibility**: RocketChat 3.0+ support dumps
**Production Tested**: ✅ RocketChat 7.8.0
**Cross-Platform Feature Parity**: ✅ 100% PowerShell ↔ Bash

## 🌟 Star this Repository
If you find this tool helpful, please consider giving it a ⭐ on GitHub!

## 🐛 Issues & Feature Requests
Found a bug or have a feature request? Please [open an issue](../../issues) on GitHub.

## 🤝 Contributing
We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.
