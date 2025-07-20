---
name: 🐛 Bug Report
about: Create a report to help us improve the RocketChat Log Automation tool
title: '[BUG] '
labels: ['bug', 'needs-triage']
assignees: ''
---

## 🐛 Bug Description
A clear and concise description of what the bug is.

## 🔄 Steps to Reproduce
Steps to reproduce the behavior:
1. Run the script with: `...`
2. Use dump file from: `...`
3. See error: `...`

## ✅ Expected Behavior
A clear and concise description of what you expected to happen.

## ❌ Actual Behavior
A clear and concise description of what actually happened.

## 📋 Environment Information
**Script Version:**
- [ ] PowerShell version
- [ ] Bash version

**Operating System:**
- [ ] Windows 10/11
- [ ] macOS
- [ ] Linux (specify distribution)
- [ ] WSL (Windows Subsystem for Linux)

**Version Details:**
- OS Version: [e.g. Windows 11 22H2]
- PowerShell Version: [e.g. 7.3.4] (run `$PSVersionTable`)
- Bash Version: [e.g. 5.1.16] (run `bash --version`)
- jq Version: [e.g. 1.6] (run `jq --version`)

## 📄 RocketChat Information
**RocketChat Version:** [e.g. 7.8.0]
**Dump File Size:** [e.g. 45MB]
**Approximate Log Entries:** [e.g. 1000]

## 🖥️ Command Used
```bash
# Paste the exact command you ran
./analyze-rocketchat-dump.sh /path/to/dump
```

## 📝 Error Output
```
Paste the error message or unexpected output here
```

## 📎 Additional Context
Add any other context about the problem here. Include screenshots if helpful.

## ✅ Checklist
- [ ] I have checked the [troubleshooting section](../../README.md#-troubleshooting) in the README
- [ ] I have tested with the test script (`./test-analyzer.sh` or `.\Test-Analyzer.ps1`)
- [ ] I have verified my environment meets the [requirements](../../README.md#-requirements)
- [ ] I have searched for [existing issues](../../issues) related to this problem
