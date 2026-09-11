# KRIYO Android APK Release Guide

This document explains how to build, test, and distribute the release APK for the **KRIYO Dual-Role Application** across physical Android phones, tablets, and emulators.

---

## 1. Project Android Configuration (Pre-configured)

The native Android layer is pre-configured with production settings:
- **Application ID**: `com.kriyo.app`
- **Application Label**: `KRIYO`
- **Minimum SDK**: Android 5.0 (API 21) — covers 99%+ of active Android devices
- **Target SDK**: Android 14 (API 34) — latest Google Play standard
- **Required Hardware & Software Permissions**:
  - `CAMERA`: AI photo capture & cataloging
  - `RECORD_AUDIO`: Voice stories & oral heritage archiving
  - `INTERNET` & `ACCESS_NETWORK_STATE`: Cloud sync & buyer marketplace
  - `READ_MEDIA_IMAGES`: Product gallery selection

---

## 2. Fast Release Build via Script

Run either of the automated build scripts located in the root of the project:

### Option A: Windows Command Prompt / Double-Click
Double-click `build_apk.bat` or open Command Prompt in the project folder and run:
```cmd
build_apk.bat
```

### Option B: Windows PowerShell
```powershell
.\build_apk.ps1
```

---

## 3. Manual Release Build Commands

If you prefer running commands manually from terminal:

```bash
# 1. Clean previous builds
flutter clean

# 2. Fetch dependencies
flutter pub get

# 3. Build universal release APK (Single APK for all devices)
flutter build apk --release

# OR 3b. Build optimized ABI-split APKs (Smaller file sizes ~15-20MB each)
flutter build apk --release --split-per-abi
```

---

## 4. Output APK Locations

Upon successful compilation, your APK files will be located at:

### Universal Release APK:
```
build/app/outputs/flutter-apk/app-release.apk
```

### ABI-Split APKs (Recommended for distribution):
```
build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk     <-- Modern Android smartphones (most common)
├── app-armeabi-v7a-release.apk   <-- Older 32-bit Android phones
└── app-x86_64-release.apk        <-- Emulators / ChromeOS devices
```

---

## 5. Installing onto an Android Phone

### Via USB Debugging (ADB):
1. Enable **Developer Options** and **USB Debugging** on your Android phone.
2. Connect your phone via USB cable.
3. Run:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Via Direct Transfer (WhatsApp, Google Drive, Email):
1. Copy `app-release.apk` (or `app-arm64-v8a-release.apk`) to your phone.
2. Open the file on your device and tap **Install**.
3. If prompted, enable **"Install unknown apps"** for your file manager or browser.

---

## 6. (Optional) Production Play Store Keystore Setup

For publishing to the Google Play Store with a custom release keystore:

1. Generate your release keystore:
```bash
keytool -genkey -v -keystore android/app/kriyo-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias kriyo
```

2. Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=kriyo
storeFile=kriyo-release-key.jks
```

3. Build Android App Bundle (AAB) for Google Play Store:
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`
