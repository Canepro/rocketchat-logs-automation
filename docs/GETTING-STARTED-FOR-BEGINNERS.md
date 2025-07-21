# 🚀 Complete Beginner's Guide to RocketChat Analyzer

**Never used command line tools before? No problem!** This guide will walk you through everything step-by-step, assuming you're starting from scratch on a fresh computer.

## 📋 What You'll Need

- ✅ A computer (Windows, Mac, or Linux)
- ✅ Internet connection
- ✅ RocketChat support dump files (we'll show you how to get test files)
- ✅ About 30 minutes for setup

---

## 🖥️ Step 1: Choose Your Operating System

### 🪟 **Windows Users (Easiest Option)**

**Option A: PowerShell (Built into Windows 10/11)**
1. **Open PowerShell**:
   - Press `Windows Key + R`
   - Type: `powershell`
   - Press Enter
   - You'll see a blue window with white text

**Option B: Install PowerShell Core (Recommended)**
1. Go to: https://github.com/PowerShell/PowerShell/releases
2. Download: `PowerShell-7.x.x-win-x64.msi`
3. Double-click to install
4. Press `Windows Key + R`, type `pwsh`, press Enter

### 🍎 **Mac Users**

**Install PowerShell Core:**
1. **Install Homebrew first** (if you don't have it):
   - Open Terminal (Applications → Utilities → Terminal)
   - Copy and paste this exactly:
     ```bash
     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
     ```
   - Press Enter and follow prompts

2. **Install PowerShell:**
   ```bash
   brew install powershell
   ```

3. **Install jq (needed for Bash version):**
   ```bash
   brew install jq
   ```

### 🐧 **Linux Users**

**Ubuntu/Debian:**
```bash
# Install PowerShell
sudo apt update
sudo apt install -y wget apt-transport-https software-properties-common
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y powershell

# Install required tools
sudo apt install -y jq curl git
```

**CentOS/RHEL:**
```bash
# Install PowerShell
sudo yum install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
sudo yum install -y powershell

# Install required tools  
sudo yum install -y jq curl git
```

---

## 📥 Step 2: Download the RocketChat Analyzer

### Method 1: Download ZIP (Easiest)
1. Go to: https://github.com/Canepro/rocketchat-logs-automation
2. Click the green **"Code"** button
3. Click **"Download ZIP"**
4. Extract the ZIP file to a folder like:
   - Windows: `C:\RocketChat-Analyzer\`
   - Mac/Linux: `~/RocketChat-Analyzer/`

### Method 2: Use Git (If you have it)
```bash
git clone https://github.com/Canepro/rocketchat-logs-automation.git
cd rocketchat-logs-automation
```

---

## 📂 Step 3: Get Test Data

### Option A: Use Our Test Data
We include comprehensive sample data in the `test-dump/` folder:
- **`standard-dump.json`** - Complete example with users, channels, and messages (recommended for beginners)
- **`minimal-dump.json`** - Basic structure example
- **Legacy format files** - For older RocketChat versions

See `test-dump/README.md` for detailed descriptions of each file.

### Option B: Get Real RocketChat Support Dump
1. **From RocketChat Admin Panel:**
   - Go to Administration → Workspace → Support
   - Click "Download Support Information"
   - Save the downloaded file/folder

2. **For Testing:** You can download sample dumps from RocketChat's documentation or use our provided test data.

---

## 🏃‍♂️ Step 4: Your First Test Run

### 🪟 **Windows Users - Super Easy Method**

**For users who prefer clicking instead of typing:**
1. Navigate to where you extracted the RocketChat Analyzer files
2. Double-click **`FIRST-TIME-SETUP.bat`**
3. This will automatically test everything for you!
4. When ready to analyze, double-click **`ANALYZE-MY-DUMP.bat`**

**Traditional PowerShell method:**
1. Navigate to where you extracted the files
2. Hold `Shift` + Right-click in the folder
3. Select "Open PowerShell window here"
4. OR: Open PowerShell and type:
   ```powershell
   cd "C:\path\to\your\RocketChat-Analyzer"
   ```

**Run your first test:**
```powershell
# Simple test to make sure everything works
.\test.ps1

# If you get an error about execution policy, run this first:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 🍎🐧 **Mac/Linux Users**

**Open Terminal in the analyzer folder:**
1. Navigate to the folder in Finder/File Manager
2. Right-click → "Open Terminal here"
3. OR: Open Terminal and type:
   ```bash
   cd ~/path/to/your/RocketChat-Analyzer
   ```

**Run your first test:**
```bash
# Make scripts executable first
chmod +x *.sh
chmod +x tests/*.sh
chmod +x scripts/*.sh

# Run the test
./test.sh
```

---

## 🎯 Step 5: Analyze Your First RocketChat Dump

### 🪟 **Windows Users - Super Easy Method**

**For users who prefer clicking:**
1. Double-click **`ANALYZE-MY-DUMP.bat`**
2. When prompted, enter: `test-dump\standard-dump.json` (for our sample data)
3. OR enter the full path to your RocketChat dump folder
4. Wait for the analysis to complete
5. Your HTML report will open automatically!

### Using the Easy Commands

**Test with our sample data first:**

```powershell
# Windows PowerShell - Test with comprehensive sample
.\analyze.ps1 -DumpPath "test-dump\standard-dump.json" -OutputFormat HTML

# Windows PowerShell - Test with minimal sample  
.\analyze.ps1 -DumpPath "test-dump\minimal-dump.json" -OutputFormat HTML

# Mac/Linux - Test with comprehensive sample
./analyze.sh --format html --output test-report.html test-dump/standard-dump.json
```

**For real RocketChat support dump folders:**

```powershell
# Windows PowerShell
.\analyze.ps1 -DumpPath "C:\path\to\your\support-dump" -OutputFormat HTML

# Mac/Linux
./analyze.sh --format html --output my-report.html /path/to/your/support-dump
```

---

## 🆘 Troubleshooting Common Issues

### ❌ "Command not found" or "File not found"

**Check you're in the right folder:**
```powershell
# Windows - should show your analyzer files
Get-ChildItem

# Mac/Linux - should show your analyzer files  
ls -la
```

**Make sure you're in the analyzer directory:**
```powershell
# Windows
cd "C:\path\to\RocketChat-Analyzer"

# Mac/Linux
cd ~/path/to/RocketChat-Analyzer
```

### ❌ "Execution policy" error (Windows)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### ❌ "Permission denied" (Mac/Linux)

```bash
chmod +x *.sh
chmod +x tests/*.sh  
chmod +x scripts/*.sh
```

### ❌ "jq: command not found" (Mac/Linux)

```bash
# Mac
brew install jq

# Ubuntu/Debian
sudo apt install jq

# CentOS/RHEL
sudo yum install jq
```

### ❌ "PowerShell not found" (Mac/Linux)

Follow the PowerShell installation steps in Step 1 above.

---

## 🎉 Step 6: Understanding Your Results

### 📊 HTML Report
- Opens automatically in your web browser
- Shows colorful charts and analysis
- Easy to read and share
- Look for:
  - 🔴 **Red sections**: Issues that need attention
  - 🟡 **Yellow sections**: Warnings to review
  - 🟢 **Green sections**: Everything looks good

### 📋 Console Output
- Shows in your terminal/PowerShell window
- Real-time analysis progress
- Summary of findings
- File locations of generated reports

---

## 🚀 Step 7: Next Steps

### Run More Comprehensive Tests
```powershell
# Windows
.\test.ps1 full

# Mac/Linux  
./test.sh full
```

### Try Different Output Formats
```powershell
# JSON format for automation
.\analyze.ps1 -DumpPath ".\test-dump" -OutputFormat JSON

# CSV format for spreadsheets
.\analyze.ps1 -DumpPath ".\test-dump" -OutputFormat CSV
```

### Explore the Documentation
- 📖 `docs/QUICK-START.md` - Quick reference
- 🏗️ `docs/ARCHITECTURE.md` - How it works
- 🧪 `docs/TESTING-GUIDE.md` - Advanced testing
- 📊 `docs/USAGE.md` - All the options

---

## 🆘 Still Need Help?

### 💬 Common Questions

**Q: I don't have any RocketChat dumps, can I still test?**
A: Yes! Use the test data in the `test-dump/` folder or run `.\test.ps1` which will auto-detect sample data.

**Q: The HTML report won't open**
A: Check if a `.html` file was created in your folder. You can double-click it to open in your browser.

**Q: I'm getting permission errors**
A: Make sure you're running PowerShell/Terminal as yourself (not administrator), and on Mac/Linux run `chmod +x *.sh` first.

**Q: Nothing happens when I run the command**
A: Check that you typed the command exactly as shown, including the `.\` or `./` at the beginning.

### 📞 Getting Support

1. **Check the error message** - it usually tells you what's wrong
2. **Look in the `docs/` folder** for more detailed guides
3. **Try the simple test first**: `.\test.ps1` or `./test.sh`
4. **Make sure you have all prerequisites** from Step 1

### ✅ Success Checklist

- [ ] Downloaded and extracted the analyzer
- [ ] Installed PowerShell (and jq on Mac/Linux)
- [ ] Can run `.\test.ps1` or `./test.sh` without errors
- [ ] Generated your first HTML report
- [ ] Opened the report in your browser

**Congratulations! You're now ready to analyze RocketChat support dumps like a pro!** 🎉

---

## 🎯 Quick Reference Card

| What I Want | Windows Command | Mac/Linux Command |
|-------------|-----------------|-------------------|
| Test everything | `.\test.ps1` | `./test.sh` |
| Basic analysis | `.\analyze.ps1 -DumpPath ".\test-dump" -OutputFormat HTML` | `./analyze.sh --format html ./test-dump` |
| Get help | `.\analyze.ps1 --help` | `./analyze.sh --help` |
| Full test suite | `.\test.ps1 full` | `./test.sh full` |

**Remember: Always make sure you're in the RocketChat-Analyzer folder when running these commands!**
