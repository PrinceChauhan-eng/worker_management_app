# Flutter D Drive Setup Guide

This guide explains how to configure Flutter to use D drive instead of C drive for temporary files and cache.

## Problem
Flutter was trying to write temporary files to C drive which ran out of space:
```
FileSystemException: writeFrom failed, path = 'C:\Users\...\AppData\Local\Temp\...'
OS Error: There is not enough space on the disk.
```

## Solution

### Quick Setup (Run the script)
1. Open PowerShell in your project directory
2. Run: `.\setup_flutter_drive.ps1`
3. Restart your terminal/IDE

### Manual Setup

#### 1. Set Environment Variables (Permanent)
Open PowerShell as Administrator and run:
```powershell
# Set TEMP and TMP to D drive
[System.Environment]::SetEnvironmentVariable("TEMP", "D:\Temp", "User")
[System.Environment]::SetEnvironmentVariable("TMP", "D:\Temp", "User")

# Set PUB_CACHE to D drive (optional, for Flutter package cache)
[System.Environment]::SetEnvironmentVariable("PUB_CACHE", "D:\FlutterCache\.pub-cache", "User")
```

#### 2. Create Directories
```powershell
New-Item -ItemType Directory -Force -Path "D:\Temp"
New-Item -ItemType Directory -Force -Path "D:\FlutterCache\.pub-cache"
```

#### 3. For Current Session (Temporary)
```powershell
$env:TEMP = "D:\Temp"
$env:TMP = "D:\Temp"
$env:PUB_CACHE = "D:\FlutterCache\.pub-cache"
```

## Verification

Check if environment variables are set:
```powershell
$env:TEMP
$env:TMP
$env:PUB_CACHE
```

## Important Notes

1. **Restart Required**: After setting environment variables, you need to:
   - Close and reopen your terminal
   - Restart VS Code/Android Studio/your IDE
   - Restart your computer (for system-wide changes)

2. **Current Session**: The script sets variables for both current session and permanently, but you may need to restart your IDE.

3. **Flutter Cache**: If you want to move Flutter's cache directory, you can also set:
   ```powershell
   $env:FLUTTER_STORAGE_BASE_URL = "https://storage.googleapis.com"
   ```

## Troubleshooting

If you still see C drive being used:
1. Verify environment variables: `Get-ChildItem Env: | Where-Object { $_.Name -match "TEMP|TMP" }`
2. Restart your IDE completely
3. Check if D drive has enough space
4. Try running Flutter commands in a fresh terminal

## Testing

After setup, try running:
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

