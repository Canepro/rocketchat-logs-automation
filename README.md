# 🚀 RocketChat Support Dump Analyzer

**Current Version:** v1.4.3 (2025-07-21)

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
- 📈 **Production Ready**: 85% validated with comprehensive testing suite and deployment guide
- 🧹 **Clean Codebase**: Optimized repository with only essential files for production use

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

**Try with sample data first:**
```powershell
# Windows PowerShell
.\analyze.ps1 -DumpPath "test-dump\standard-dump.json" -OutputFormat HTML

# Linux/macOS Bash
./analyze.sh --format html test-dump/standard-dump.json
```

**Analyze your own dump:**
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
│   ├── GETTING-STARTED-FOR-BEGINNERS.md # Complete beginner's guide
│   ├── INSTALLATION.md                # Quick installation guide
│   ├── ARCHITECTURE.md                # Technical architecture
│   ├── PRODUCTION-READY.md            # Production deployment guide
│   ├── PRODUCTION-DEPLOYMENT.md       # Comprehensive deployment guide
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
    ├── README.md                       # Guide to sample files
    ├── standard-dump.json              # Complete sample (users, channels, messages)
    ├── minimal-dump.json               # Basic sample structure
    ├── 7.8.0-statistics.json          # Legacy format samples
    ├── 7.8.0-settings.json            # 
    └── 7.8.0-server.log               # 
```

## 📚 Documentation

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
| [🤝 Contributing](docs/CONTRIBUTING.md) | Contribution guidelines |

## 📋 Prerequisites

- **RocketChat support dump files** (any 7.x version)
- **PowerShell 5.1+** (Windows) or **PowerShell Core 7+** (cross-platform)
- **Bash 4.0+** with `jq`, `grep`, `awk`, `sed` (Linux/macOS)

## 🎯 Usage Examples

### Basic Analysis
```powershell
# Test with sample data first (recommended for beginners)
.\analyze.ps1 -DumpPath "test-dump\standard-dump.json" -OutputFormat HTML

# Generate HTML report from real dump  
.\analyze.ps1 -DumpPath "C:\dump" -OutputFormat HTML

# Console output with warnings only  
.\analyze.ps1 -DumpPath "C:\dump" -OutputFormat Console
```

### Advanced Options
```bash
# Bash version with HTML output
./analyze.sh --format html --output analysis.html /path/to/dump

# JSON export for automation
./analyze.sh --format json --output analysis.json /path/to/dump
```

### Testing Options
```bash
# Quick test (2-3 minutes)
.\test.ps1          # Windows
./test.sh           # Linux/macOS

# Comprehensive test (5-10 minutes)  
.\test.ps1 full     # Windows
./test.sh full      # Linux/macOS
```

## 🧪 Testing & Validation

### Quick Validation (2-3 minutes)
```bash
# Test both PowerShell and Bash versions
.\test.ps1    # Windows
./test.sh     # Linux/macOS
```

### Production Readiness Test (5-10 minutes)
```bash
# Comprehensive validation suite
.\test.ps1 full    # Windows
./test.sh full     # Linux/macOS
```

### Complete Test Suite (10-20 minutes)
```bash
# Test all available dumps with full validation
.\test.ps1 all     # Windows
./test.sh all      # Linux/macOS
```

See [Testing Guide](./docs/TESTING-GUIDE.md) for detailed testing documentation.

## 📊 Output Formats

| Format | Description | Use Case |
|--------|-------------|----------|
| **Console** | Colored terminal output | Quick analysis, CI/CD |
| **HTML** | Interactive web report | Detailed review, sharing |
| **JSON** | Structured data output | Automation, integration |
| **CSV** | Spreadsheet format | Data analysis, tracking |

## 🎯 Key Benefits

- ✅ **Fast**: Analysis completes in 1-3 minutes
- ✅ **Comprehensive**: 75+ validation checks across all RocketChat components
- ✅ **Cross-Platform**: Works on Windows, Linux, and macOS
- ✅ **Professional**: Enterprise-ready with production validation
- ✅ **User-Friendly**: Simple commands, clear output, detailed reports
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

**⚡ Ready to analyze your RocketChat environment? Start with `.\test.ps1` (Windows) or `./test.sh` (Linux/macOS) to validate everything works!**
