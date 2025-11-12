# Simple Launch Script - Run Flutter on default port
# This script runs Flutter without D drive configuration

Write-Host "Launching Flutter..." -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green

Write-Host "Starting Flutter web server" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow

# Run Flutter on default port
flutter run -d chrome