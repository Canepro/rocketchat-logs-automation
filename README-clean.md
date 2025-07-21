# 🚀 RocketChat Support Dump Analyzer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Production Ready](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)](./docs/PRODUCTION-READY.md)

A comprehensive automation tool for analyzing RocketChat support dumps and system logs. Provides detailed health scoring, performance analysis, security auditing, and professional reporting.

## ✨ Features

- 🔍 **Comprehensive Analysis**: Logs, settings, statistics, Omnichannel, and apps
- 📊 **Multi-Format Reports**: Console, JSON, CSV, and interactive HTML
- 🎯 **Health Scoring**: Automated assessment with actionable recommendations  
- 🔐 **Security Auditing**: Identifies vulnerabilities and compliance issues
- ⚡ **Performance Analysis**: Resource usage and optimization suggestions
- 🌐 **Cross-Platform**: PowerShell and Bash versions with feature parity
- 📈 **Production Ready**: 75% validated with comprehensive testing suite

## 🚀 Quick Start

### Option 1: Easy Testing (Recommended)
```bash
# Windows
tests\test-analyzer.bat

# Linux/macOS  
./tests/test-analyzer.sh
```

### Option 2: Direct Usage
```powershell
# PowerShell (Windows/Linux/macOS)
.\scripts\Analyze-RocketChatDump.ps1 -DumpPath "C:\path\to\dump" -OutputFormat HTML

# Bash (Linux/macOS)
./scripts/analyze-rocketchat-dump.sh --format html --output report.html /path/to/dump
```

## 📁 Project Structure

```
├── scripts/                    # Main analyzer scripts
│   ├── Analyze-RocketChatDump.ps1   # PowerShell version
│   └── analyze-rocketchat-dump.sh   # Bash version
├── tests/                      # Testing and validation
│   ├── Production-Readiness-Test.ps1 # Comprehensive test suite
│   ├── Quick-CrossPlatform-Test.ps1  # Fast validation
│   ├── test-analyzer.bat            # Windows test interface
│   └── test-analyzer.sh             # Linux/macOS test interface
├── docs/                       # Documentation
│   ├── TESTING-GUIDE.md            # Complete testing guide
│   └── PRODUCTION-READY.md         # Production deployment guide
├── config/                     # Configuration files
├── examples/                   # Usage examples and samples
└── README.md                   # This file
```

## 📋 Prerequisites

- **RocketChat support dump files** (any 7.x version)
- **PowerShell 5.1+** (Windows) or **PowerShell Core 7+** (cross-platform)
- **Bash 4.0+** with `jq`, `grep`, `awk`, `sed` (Linux/macOS)

## 🎯 Usage Examples

### Basic Analysis
```powershell
# Generate HTML report
.\scripts\Analyze-RocketChatDump.ps1 -DumpPath "C:\dump" -OutputFormat HTML -ExportPath "report.html"

# Console output with warnings only
.\scripts\Analyze-RocketChatDump.ps1 -DumpPath "C:\dump" -Severity Warning
```

### Advanced Options
```bash
# Custom configuration with verbose output
./scripts/analyze-rocketchat-dump.sh --config custom-rules.json --verbose --severity error /path/to/dump

# JSON export for automation
./scripts/analyze-rocketchat-dump.sh --format json --output analysis.json /path/to/dump
```

## 🧪 Testing & Validation

### Quick Validation (2-3 minutes)
```bash
# Test both PowerShell and Bash versions
./tests/test-analyzer.sh
```

### Production Readiness Test (5-10 minutes)
```bash
# Comprehensive validation suite
./tests/test-analyzer.sh full
```

### Complete Test Suite (10-20 minutes)
```bash
# Test all available dumps with full validation
./tests/test-analyzer.sh all
```

See [Testing Guide](./docs/TESTING-GUIDE.md) for detailed testing documentation.

## 📊 Output Formats

| Format | Description | Use Case |
|--------|-------------|----------|
| **Console** | Colored terminal output | Quick analysis, CI/CD |
| **HTML** | Interactive web report | Sharing, presentations |
| **JSON** | Structured data | Automation, integrations |
| **CSV** | Spreadsheet format | Data analysis, reporting |

## 🎛️ Configuration

Customize analysis rules, patterns, and thresholds:

```json
{
  "logPatterns": {
    "error": ["error", "exception", "failed"],
    "security": ["auth", "unauthorized", "breach"]
  },
  "healthThresholds": {
    "memory": { "warning": 80, "critical": 95 },
    "disk": { "warning": 85, "critical": 98 }
  }
}
```

## 🏥 Health Scoring

Automated assessment across multiple dimensions:

- **🔍 Log Analysis**: Error patterns, security events
- **⚙️ Configuration**: Security settings, performance tuning  
- **📈 Performance**: Resource usage, optimization opportunities
- **🔒 Security**: Vulnerabilities, compliance issues
- **🚀 Operational**: Uptime, maintenance recommendations

## 🌟 Why This Tool?

- ✅ **Saves Hours**: Automated analysis vs manual review
- ✅ **Consistent**: Standardized assessment methodology  
- ✅ **Actionable**: Specific recommendations, not just problems
- ✅ **Professional**: Publication-ready reports
- ✅ **Reliable**: Production-tested with 75% validation rate

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and test thoroughly
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📖 **Documentation**: [docs/](./docs/)
- 🧪 **Testing Guide**: [docs/TESTING-GUIDE.md](./docs/TESTING-GUIDE.md)
- 🚀 **Production Guide**: [docs/PRODUCTION-READY.md](./docs/PRODUCTION-READY.md)
- 🐛 **Issues**: [GitHub Issues](https://github.com/Canepro/rocketchat-logs-automation/issues)

---

**⚡ Ready to analyze your RocketChat environment? Start with `./tests/test-analyzer.sh` to validate everything works!**
