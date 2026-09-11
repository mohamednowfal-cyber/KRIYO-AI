@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo        KRIYO Android APK Release Build Script
echo ========================================================
echo.

REM Automatically detect and add Flutter and bundled git to PATH
if exist "C:\src\flutter\bin" (
    set "PATH=C:\src\flutter\bin;C:\src\flutter\bin\mingit\cmd;!PATH!"
)
if exist "%USERPROFILE%\Downloads\flutter_windows_3.24.3-stable\flutter\bin" (
    set "PATH=%USERPROFILE%\Downloads\flutter_windows_3.24.3-stable\flutter\bin;%USERPROFILE%\Downloads\flutter_windows_3.24.3-stable\flutter\bin\mingit\cmd;!PATH!"
)

REM Automatically detect Android SDK location
if not defined ANDROID_HOME (
    if exist "%LOCALAPPDATA%\Android\Sdk" (
        set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
        set "PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools;!PATH!"
    )
)

REM Automatically detect Java JDK (prioritize JDK 17 for Gradle compatibility)
if not defined JAVA_HOME (
    if exist "C:\Program Files\Microsoft\jdk-17*" (
        for /d %%i in ("C:\Program Files\Microsoft\jdk-17*") do (
            set "JAVA_HOME=%%i"
            set "PATH=%%i\bin;!PATH!"
        )
    ) else if exist "C:\Program Files\Android\Android Studio\jbr" (
        set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
        set "PATH=C:\Program Files\Android\Android Studio\jbr\bin;!PATH!"
    )
)

REM Remove stale lock files if previous run was interrupted
if exist "C:\src\flutter\bin\cache\flutter.bat.lock" (
    del /f /q "C:\src\flutter\bin\cache\flutter.bat.lock" >nul 2>&1
)

where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter SDK was not found in your system PATH or C:\src\flutter\bin.
    echo.
    echo To build and release the APK:
    echo 1. Ensure Flutter is extracted to C:\src\flutter
    echo 2. Run this script again or run:
    echo    flutter build apk --release
    echo.
    pause
    exit /b 1
)

echo [OK] Flutter SDK detected!
echo.

echo [1/3] Resolving KRIYO dependencies...
call flutter.bat pub get

echo.
echo [2/3] Compiling Release APK for Android Devices...
call flutter.bat build apk --release

echo.
echo ========================================================
echo [SUCCESS] Release APK built successfully!
echo.
echo Location of release APK:
echo   build\app\outputs\flutter-apk\app-release.apk
echo.
echo You can directly install this APK onto any Android device via:
echo   adb install build\app\outputs\flutter-apk\app-release.apk
echo ========================================================
pause
