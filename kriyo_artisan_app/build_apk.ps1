# KRIYO Android APK Release Build Script (PowerShell)
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "       KRIYO Android APK Release Build Script          " -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Auto-detect Flutter in C:\src\flutter\bin
if (Test-Path "C:\src\flutter\bin") {
    $env:PATH = "C:\src\flutter\bin;C:\src\flutter\bin\mingit\cmd;" + $env:PATH
}

# Auto-detect Android SDK
if (-not $env:ANDROID_HOME -and (Test-Path "$env:LOCALAPPDATA\Android\Sdk")) {
    $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
    $env:PATH = "$env:LOCALAPPDATA\Android\Sdk\platform-tools;" + $env:PATH
}

# Auto-detect Java JDK
if (-not $env:JAVA_HOME -and (Test-Path "C:\Program Files\Android\Android Studio\jbr")) {
    $env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
    $env:PATH = "C:\Program Files\Android\Android Studio\jbr\bin;" + $env:PATH
}

# Remove stale lock if needed
if (Test-Path "C:\src\flutter\bin\cache\flutter.bat.lock") {
    Remove-Item -Force "C:\src\flutter\bin\cache\flutter.bat.lock" -ErrorAction SilentlyContinue
}

$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Host "[ERROR] Flutter SDK is not detected in your system PATH or C:\src\flutter." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure Flutter SDK is located at C:\src\flutter" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host "[OK] Flutter SDK detected successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "[1/2] Resolving dependencies (flutter pub get)..." -ForegroundColor Green
& flutter pub get

Write-Host ""
Write-Host "[2/2] Compiling release APK..." -ForegroundColor Green
& flutter build apk --release

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "[SUCCESS] KRIYO Android Release APK successfully compiled!" -ForegroundColor Green
Write-Host ""
Write-Host "Generated APK Location:" -ForegroundColor White
Write-Host "  build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Yellow
Write-Host ""
Write-Host "To install directly to a connected Android phone:" -ForegroundColor White
Write-Host "  adb install -r build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Read-Host "Press Enter to finish..."
