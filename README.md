# RocketChat Support Dump Analyzer

A comprehensive automation tool for analyzing RocketChat support dumps and system logs. Available in both **PowerShell** and **Bash** versions to support different environments and preferences. This tool helps support engineers quickly identify issues, analyze performance metrics, and generate detailed reports from RocketChat support data.

## 🚀 Features

- **Dual Implementation**: Both PowerShell and Bash versions with identical functionality
- **Comprehensive Analysis**: Analyzes logs, settings, statistics, Omnichannel configuration, and installed apps
- **Multiple Output Formats**: Console, JSON, CSV, and HTML reports
- **Pattern Recognition**: Automatically detects error patterns and trends
- **Health Scoring**: Provides overall system health scores and component-specific metrics
- **Security Analysis**: Reviews security settings and identifies potential vulnerabilities
- **Performance Insights**: Analyzes memory usage, user load, and system performance
- **Configurable Rules**: Customizable analysis rules and thresholds
- **Professional Reports**: Generate presentation-ready HTML reports
- **Cross-Platform**: Works on Windows, macOS, and Linux

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

#### Generate HTML Report
```powershell
.\Analyze-RocketChatDump.ps1 -DumpPath "C:\Downloads\7.8.0-support-dump" -OutputFormat HTML -ExportPath "report.html"
```

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

## 📁 Project Structure

```
Rocketchat_Logs_Automation/
├── Analyze-RocketChatDump.ps1    # Main PowerShell analysis script
├── analyze-rocketchat-dump.sh    # Main Bash analysis script
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
- Error and warning detection
- Pattern recognition and frequency analysis
- Timeline analysis
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

**Version**: 1.2.0  
**Last Updated**: 2025-07-20  
**Compatibility**: RocketChat 3.0+ support dumps

## 🌟 Star this Repository
If you find this tool helpful, please consider giving it a ⭐ on GitHub!

## 🐛 Issues & Feature Requests
Found a bug or have a feature request? Please [open an issue](../../issues) on GitHub.

## 🤝 Contributing
We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.
