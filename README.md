# 🚀 RocketChat Support Dump Analyzer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](htt## 📚 Documentation

| Document | Description |
|----------|-------------|
| [🆕 **Beginner's Guide**](docs/GETTING-STARTED-FOR-BEGINNERS.md) | **Complete step-by-step setup for first-time users** |
| [⚡ Installation Guide](docs/INSTALLATION.md) | Quick 5-minute setup |
| [📖 Quick Start Guide](docs/QUICK-START.md) | Get started in 5 minutes |
| [🏗️ Architecture](docs/ARCHITECTURE.md) | Technical architecture and design |
| [🧪 Testing Guide](docs/TESTING-GUIDE.md) | Comprehensive testing procedures |
| [🚀 Production Ready](docs/PRODUCTION-READY.md) | Production deployment guide |
| [📊 Usage Examples](docs/USAGE.md) | Detailed usage instructions |
| [🔄 Compatibility](docs/COMPATIBILITY.md) | Platform compatibility matrix |
| [📝 Changelog](docs/CHANGELOG.md) | Version history and changes |
| [🤝 Contributing](docs/CONTRIBUTING.md) | Contribution guidelines |rce.org/licenses/MIT)
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

### 🆕 **New to Command Line Tools?**
👉 **[Complete Beginner's Guide](docs/GETTING-STARTED-FOR-BEGINNERS.md)** 👈  
*Never used PowerShell or terminal before? This guide walks you through everything from scratch.*

### ⚡ **For Everyone Else**

**Test it works:**
```bash
# Windows
.\test.ps1

# Linux/macOS  
./test.sh
```

**Analyze your dump:**
```powershell
# Windows PowerShell
.\analyze.ps1 -DumpPath "C:\path\to\dump" -OutputFormat HTML

# Linux/macOS Bash
./analyze.sh --format html --output report.html /path/to/dump
```

**That's it!** Your HTML report opens automatically in your browser.

## 📁 Project Structure

```
🚀 RocketChat Support Dump Analyzer/
├── 📄 analyze.ps1/.sh/.bat         # Easy entry points for analysis
├── 📄 test.ps1/.sh/.bat            # Easy entry points for testing
├── 📄 README.md                    # This file
├── 📄 LICENSE                      # MIT License
│
├── 📂 scripts/                     # Main analyzer scripts
│   ├── Analyze-RocketChatDump.ps1      # PowerShell version (primary)
│   ├── analyze-rocketchat-dump.sh      # Bash version (Linux/macOS)
│   └── Clean-AnalyzerOutputs.ps1       # Utility to clean old reports
│
├── 📂 tests/                       # Testing and validation suite
│   ├── Production-Readiness-Test.ps1   # Comprehensive production validation
│   ├── Quick-CrossPlatform-Test.ps1    # Fast cross-platform testing
│   ├── test-analyzer.bat              # Windows test interface
│   ├── test-analyzer.sh               # Linux/macOS test interface
│   ├── test-analyzer-clean.sh         # Alternative test script
│   ├── Test-Analyzer.ps1              # Additional PowerShell tests
│   ├── Test-Simple.ps1                # Simple validation tests
│   ├── Test-InteractiveLogs.ps1       # Interactive log testing
│   ├── test-debug.sh                  # Debug testing script
│   └── bash-test-new.sh               # Bash-specific tests
│
├── 📂 docs/                        # Documentation
│   ├── PRODUCTION-READY.md            # Production deployment guide
│   ├── TESTING-GUIDE.md               # Testing and validation guide
│   ├── CHANGELOG.md                   # Version history
│   ├── COMPATIBILITY.md               # Platform compatibility matrix
│   ├── CONTRIBUTING.md                # Contribution guidelines
│   ├── FEATURE-PLAN-v1.4.0.md        # Future development plans
│   ├── QUICK-START.md                 # Quick start guide
│   ├── RELEASE_NOTES.md               # Release notes
│   ├── USAGE.md                       # Detailed usage instructions
│   └── COMPARISON.md                  # Feature comparison
│
├── 📂 examples/                    # Sample files and demonstrations
│   ├── sample-reports/                # Example HTML reports
│   ├── Create-InteractiveDemo.ps1     # Interactive demo generator
│   ├── Generate-Report-Simple.ps1     # Simple report generator
│   ├── Generate-Report.ps1            # Advanced report generator
│   ├── generate-report.bat            # Windows batch example
│   ├── analyze-bash.bat               # Bash wrapper example
│   ├── debug_output.txt               # Sample debug output
│   └── full_output.txt                # Sample full output
│
├── 📂 modules/                     # PowerShell modules
│   ├── RocketChatLogParser.psm1       # Log parsing functionality
│   ├── RocketChatAnalyzer.psm1        # Analysis engine
│   └── ReportGenerator.psm1           # Report generation
│
├── 📂 config/                      # Configuration files
│   ├── analysis-rules.json            # Analysis rules and patterns
│   └── report-templates/              # Report templates
│
└── 📂 test-dump/                   # Sample test data
    └── (RocketChat support dump samples)
```
├── docs/                       # Documentation
│   ├── TESTING-GUIDE.md            # Complete testing guide
│   └── PRODUCTION-READY.md         # Production deployment guide
├── config/                     # Configuration files
├── examples/                   # Usage examples and samples
└── README.md                   # This file
```

## � Documentation

| Document | Description |
|----------|-------------|
| [📖 Quick Start Guide](docs/QUICK-START.md) | Get started in 5 minutes |
| [🏗️ Architecture](docs/ARCHITECTURE.md) | Technical architecture and design |
| [🧪 Testing Guide](docs/TESTING-GUIDE.md) | Comprehensive testing procedures |
| [🚀 Production Ready](docs/PRODUCTION-READY.md) | Production deployment guide |
| [📊 Usage Examples](docs/USAGE.md) | Detailed usage instructions |
| [🔄 Compatibility](docs/COMPATIBILITY.md) | Platform compatibility matrix |
| [📝 Changelog](docs/CHANGELOG.md) | Version history and changes |
| [🤝 Contributing](docs/CONTRIBUTING.md) | Contribution guidelines |

## �📋 Prerequisites

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
