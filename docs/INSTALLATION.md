# ⚡ Quick Installation Guide

## 🎯 For Complete Beginners

**Never used command line tools? Start here:** 
👉 **[Complete Beginner's Guide](GETTING-STARTED-FOR-BEGINNERS.md)** 👈

This guide assumes you know nothing and walks you through everything step-by-step.

---

## 🚀 For Everyone Else (5-Minute Setup)

### Step 1: Download
```bash
# Method 1: Download ZIP from GitHub
# Go to: https://github.com/Canepro/rocketchat-logs-automation
# Click "Code" → "Download ZIP"

# Method 2: Git clone
git clone https://github.com/Canepro/rocketchat-logs-automation.git
cd rocketchat-logs-automation
```

### Step 2: Install Prerequisites

**Windows (PowerShell built-in)**
- ✅ Ready to go! (Windows 10/11 has PowerShell)
- Optional: Install PowerShell Core for best experience

**Mac**
```bash
brew install powershell jq
```

**Linux (Ubuntu/Debian)**
```bash
sudo apt update && sudo apt install -y powershell jq
```

### Step 3: Test It Works
```bash
# Windows
.\test.ps1

# Mac/Linux  
./test.sh
```

### Step 4: Analyze Your First Dump
```bash
# Windows
.\analyze.ps1 -DumpPath "C:\path\to\dump" -OutputFormat HTML

# Mac/Linux
./analyze.sh --format html --output report.html /path/to/dump
```

**Done! 🎉** Your HTML report will open automatically.

---

## 🆘 Need Help?

- 🆕 **New to command line?** → [Beginner's Guide](GETTING-STARTED-FOR-BEGINNERS.md)
- ⚡ **Quick reference?** → [Quick Start](QUICK-START.md)
- 🔧 **Troubleshooting?** → [Testing Guide](TESTING-GUIDE.md)
- 📖 **All options?** → [Usage Guide](USAGE.md)

## ✅ Verification

**You're ready when:**
- [ ] `.\test.ps1` or `./test.sh` runs without errors
- [ ] You get an HTML report in your browser
- [ ] The test shows "✅ SUCCESS" messages

**Total setup time: 5-15 minutes depending on your system**
