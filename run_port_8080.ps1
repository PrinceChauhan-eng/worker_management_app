# Quick Launch Script - Run Flutter on Port 8080
# This script sets D drive environment variables and runs Flutter on port 8080

Write-Host "🚀 Launching Flutter on Port 8080..." -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Set all temp-related environment variables to D drive
$env:TEMP = "D:\Temp"
$env:TMP = "D:\Temp"
$env:DART_TMPDIR = "D:\Temp"
$env:FLUTTER_TMPDIR = "D:\Temp"
$env:PUB_CACHE = "D:\FlutterCache\.pub-cache"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path "D:\Temp" | Out-Null
New-Item -ItemType Directory -Force -Path "D:\FlutterCache\.pub-cache" | Out-Null

Write-Host "✓ Environment configured for D drive" -ForegroundColor Cyan
Write-Host "✓ Starting Flutter web server on http://localhost:8080" -ForegroundColor Cyan
Write-Host "`nPress Ctrl+C to stop the server`n" -ForegroundColor Yellow

# Run Flutter on port 8080
flutter run -d chrome --web-port=8080

