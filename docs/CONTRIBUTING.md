# Contributing to RocketChat Log Automation

Thank you for your interest in contributing to this project! This tool helps RocketChat support teams and administrators analyze support dumps more effectively.

## 🎯 How to Contribute

### Reporting Issues
- Use the [GitHub Issues](../../issues) page to report bugs
- Include detailed steps to reproduce the issue
- Provide sample RocketChat dump data (sanitized) if relevant
- Specify your environment (OS, PowerShell/Bash version, etc.)

### Suggesting Features
- Open a [feature request issue](../../issues/new)
- Describe the use case and expected behavior
- Explain how it would benefit RocketChat support workflows

### Code Contributions

#### Getting Started
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly with both PowerShell and Bash versions
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

#### Development Guidelines

**Code Style**
- **PowerShell**: Follow PowerShell best practices, use approved verbs
- **Bash**: Follow POSIX compliance where possible, use shellcheck
- **JSON**: Validate all JSON configurations with proper formatting
- **Documentation**: Update README.md and inline comments

**Testing Requirements**
- Test both PowerShell and Bash implementations
- Verify cross-platform compatibility (Windows, Linux, macOS)
- Test with real RocketChat dump data when possible
- Ensure backwards compatibility with existing dump formats

**Performance Considerations**
- Optimize for large dump files (1000+ log entries)
- Minimize memory usage for resource-constrained environments
- Maintain fast analysis times (<30 seconds for typical dumps)

#### Pull Request Process

1. **Description**: Provide clear description of changes and motivation
2. **Testing**: Include test results and any new test cases
3. **Documentation**: Update relevant documentation
4. **Backwards Compatibility**: Ensure existing functionality isn't broken
5. **Review**: Address any feedback from maintainers

#### Branch Naming Convention
- `feature/` - New features
- `bugfix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test improvements

## 🧪 Testing

### Local Testing
```bash
# Test bash version
./test-analyzer.sh

# Test PowerShell version (Windows/PowerShell Core)
.\Test-Analyzer.ps1
```

### Test with Real Data
Always test with actual RocketChat support dumps when making analysis changes:
```bash
# Replace with actual dump path
./analyze-rocketchat-dump.sh /path/to/real-dump
```

## 📝 Documentation Standards

- **README.md**: Keep examples current and accurate
- **Inline Comments**: Document complex logic and analysis patterns
- **Configuration**: Document any new configuration options
- **Examples**: Provide working examples for new features

## 🔧 Development Environment Setup

### Prerequisites
- **PowerShell**: PowerShell 5.1+ or PowerShell Core 7+
- **Bash**: Bash 4.0+, jq, standard Unix tools
- **Git**: For version control
- **Editor**: VS Code recommended with PowerShell and Bash extensions

### Recommended Tools
- **PowerShell**: PSScriptAnalyzer for code quality
- **Bash**: shellcheck for script validation
- **JSON**: jq for testing JSON parsing
- **Testing**: Real RocketChat support dumps for validation

## 🎯 Priority Areas for Contribution

### High Priority
- **New RocketChat Version Support**: Update parsers for new dump formats
- **Performance Optimization**: Improve analysis speed for large dumps
- **Error Handling**: Enhance robustness with malformed dumps
- **Security Analysis**: Expand security configuration checks

### Medium Priority
- **Visualization**: Enhanced HTML reports with charts
- **Integration**: APIs for external monitoring systems
- **Automation**: CI/CD pipeline integration features
- **Mobile**: Responsive HTML reports

### Welcome Contributions
- **Documentation**: Improve examples and troubleshooting
- **Testing**: Additional test cases and edge case handling
- **Localization**: Support for non-English RocketChat instances
- **Platform Support**: Enhanced Windows/WSL integration

## 📞 Getting Help

- **Questions**: Open a [GitHub Discussion](../../discussions)
- **Issues**: Use [GitHub Issues](../../issues) for bugs
- **Security**: For security concerns, please email privately first

## 🙏 Recognition

Contributors will be recognized in:
- README.md contributor section
- Release notes for significant contributions
- GitHub contributor statistics

Thank you for helping improve RocketChat support workflows! 🚀
