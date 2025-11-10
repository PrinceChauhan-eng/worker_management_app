# Flutter D Drive Setup Script
# This script configures Flutter to use D drive instead of C drive for temporary files and cache

Write-Host "Setting up Flutter to use D Drive..." -ForegroundColor Green

# Create directories on D drive
Write-Host "Creating directories on D drive..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "D:\Temp" | Out-Null
New-Item -ItemType Directory -Force -Path "D:\FlutterCache" | Out-Null
New-Item -ItemType Directory -Force -Path "D:\FlutterCache\.pub-cache" | Out-Null

# Set environment variables for current session
Write-Host "Setting environment variables for current session..." -ForegroundColor Yellow
$env:TEMP = "D:\Temp"
$env:TMP = "D:\Temp"
$env:PUB_CACHE = "D:\FlutterCache\.pub-cache"

# Set environment variables permanently (User level)
Write-Host "Setting environment variables permanently..." -ForegroundColor Yellow
[System.Environment]::SetEnvironmentVariable("TEMP", "D:\Temp", "User")
[System.Environment]::SetEnvironmentVariable("TMP", "D:\Temp", "User")
[System.Environment]::SetEnvironmentVariable("PUB_CACHE", "D:\FlutterCache\.pub-cache", "User")

Write-Host "`nConfiguration complete!" -ForegroundColor Green
Write-Host "Current settings:" -ForegroundColor Cyan
Write-Host "  TEMP: $env:TEMP"
Write-Host "  TMP: $env:TMP"
Write-Host "  PUB_CACHE: $env:PUB_CACHE"
Write-Host "`nNote: You may need to restart your terminal or IDE for changes to take full effect." -ForegroundColor Yellow

