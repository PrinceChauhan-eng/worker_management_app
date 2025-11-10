# 🚀 Running Flutter Project on Port 8080

## Quick Start

### Option 1: Use the Quick Launch Script (Recommended)
```powershell
.\run_port_8080.ps1
```

This script:
- ✅ Sets all D drive environment variables
- ✅ Runs Flutter on port 8080
- ✅ Opens in Chrome automatically

### Option 2: Manual Command
```powershell
$env:TEMP = "D:\Temp"
$env:TMP = "D:\Temp"
$env:DART_TMPDIR = "D:\Temp"
$env:FLUTTER_TMPDIR = "D:\Temp"
flutter run -d chrome --web-port=8080
```

### Option 3: Using the General Run Script
```powershell
.\run_flutter.ps1 "run -d chrome --web-port=8080"
```

## Access Your App

Once Flutter starts, open your browser and navigate to:
```
http://localhost:8080
```

## Stop the Server

Press `Ctrl+C` in the terminal where Flutter is running.

## Troubleshooting

### If port 8080 is already in use:
```powershell
# Use a different port
flutter run -d chrome --web-port=8081
```

### If you get C drive space error:
1. Make sure environment variables are set (scripts do this automatically)
2. Restart VS Code if running from IDE
3. Use the run scripts provided

## Current Status

✅ Flutter is configured to use D drive for temporary files
✅ Port 8080 is configured
✅ Quick launch scripts are ready

Just run `.\run_port_8080.ps1` to start!

