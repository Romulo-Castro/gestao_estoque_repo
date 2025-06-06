# 🚀 Quick Deployment Commands

## Development Commands
```powershell
# Navigate to frontend directory
cd frontend

# Get dependencies
flutter pub get

# Run code analysis
flutter analyze

# Run tests
flutter test

# Run in debug mode
flutter run
```

## Production Build Commands
```powershell
# Clean build
flutter clean
flutter pub get

# Android Production Build
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS Production Build (macOS only)
flutter build ios --release

# Web Build
flutter build web --release
```

## Quality Assurance
```powershell
# Run full analysis
flutter analyze --no-congratulate

# Format code
flutter format lib/

# Check dependencies
flutter pub deps

# Doctor check
flutter doctor -v
```

## Files Generated
- `build/app/outputs/flutter-apk/app-release.apk` (Android APK)
- `build/app/outputs/bundle/release/app-release.aab` (Android Bundle)
- `build/ios/iphoneos/Runner.app` (iOS App)
- `build/web/` (Web deployment files)

## Quick Validation
```powershell
# Verify all critical files exist
Get-ChildItem frontend\lib\main.dart
Get-ChildItem frontend\pubspec.yaml
Get-ChildItem frontend\lib\providers\
Get-ChildItem frontend\lib\screens\
Get-ChildItem frontend\lib\services\
```

## 🎯 Ready for Production! ✅
