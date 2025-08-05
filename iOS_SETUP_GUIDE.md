# 🍎 TripMate iOS Setup Guide

## Prerequisites on Mac

### 1. Install Xcode
```bash
# Download Xcode from Mac App Store (it's free)
# Or download from developer.apple.com
# Make sure to install Xcode Command Line Tools
xcode-select --install
```

### 2. Install Flutter on Mac
```bash
# Download Flutter SDK
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH (add this to ~/.zshrc or ~/.bash_profile)
export PATH="$PATH:$HOME/development/flutter/bin"

# Reload terminal
source ~/.zshrc
```

### 3. Install CocoaPods
```bash
sudo gem install cocoapods
```

### 4. Verify Setup
```bash
flutter doctor
```

## Running TripMate on iOS

### 1. Navigate to Project
```bash
cd path/to/tripmate
```

### 2. Get Dependencies
```bash
flutter pub get
```

### 3. Install iOS Dependencies
```bash
cd ios
pod install
cd ..
```

### 4. Open iOS Simulator
```bash
open -a Simulator
```

### 5. Run on Simulator
```bash
flutter run -d ios
```

### 6. Run on Physical iPhone/iPad
```bash
# Connect your iOS device via USB
# Enable Developer Mode on device (Settings > Privacy & Security > Developer Mode)
flutter devices  # See your connected device
flutter run -d "Your iPhone Name"
```

## iOS-Specific Features Ready

✅ **Location Permissions**: Already added to Info.plist
✅ **GPS Tracking**: Works offline on iOS
✅ **Map Integration**: Cached tiles for offline use
✅ **Hive Storage**: Local database for trip data
✅ **Modern UI**: iOS-native look and feel

## Troubleshooting

### Common Issues:
1. **Pod Install Fails**: `pod repo update && pod install`
2. **Simulator Not Found**: `xcrun simctl list devices`
3. **Code Signing**: Use your Apple Developer account or free provisioning
4. **Permission Denied**: Make sure Xcode license is accepted: `sudo xcodebuild -license`

### iOS Specific Testing:
- **Location Services**: Test GPS accuracy and permissions
- **Background App Refresh**: Test location tracking when app is backgrounded
- **App Store Guidelines**: Location usage descriptions are already configured
- **Privacy**: Users will see clear permission requests

## Physical Device Testing

1. **Connect iPhone/iPad** via USB
2. **Trust Computer** on device when prompted
3. **Enable Developer Mode** (iOS 16+): Settings > Privacy & Security > Developer Mode
4. **Run**: `flutter run` will automatically detect your device

Your TripMate app includes:
- 📍 Real-time GPS tracking (works offline)
- 🗺️ Offline maps with cached tiles
- 💾 Local data storage with Hive
- 🎨 Modern iOS-compatible UI
- 🔒 Proper location permissions configured

## ⚡ Hot Reload & Development

### VS Code Development (Automatic Hot Reload)
1. **Start Debug Mode**: Press `F5` or use "Run and Debug" panel
2. **Auto Hot Reload**: Changes save automatically and reload instantly
3. **Manual Controls**: 
   - `Ctrl+F5` (Windows) / `Cmd+F5` (Mac): Hot Reload
   - `Ctrl+Shift+F5` / `Cmd+Shift+F5`: Hot Restart

### Terminal Development
1. **Start**: `flutter run -d ios`
2. **Hot Reload**: Press `r` in terminal
3. **Hot Restart**: Press `R` in terminal  
4. **Quit**: Press `q` in terminal

### What Triggers Hot Reload:
✅ **UI Changes**: Widget modifications, styling updates
✅ **Logic Changes**: Function updates, state changes
✅ **New Widgets**: Adding/removing widgets
❌ **Structure Changes**: New files, dependency changes (need Hot Restart)
❌ **main() Changes**: App initialization changes (need full restart)

### Development Tips:
- **Save to Reload**: Every save triggers hot reload automatically
- **See Changes Instantly**: UI updates appear in ~1 second
- **Keep App State**: Hot reload preserves your navigation and data
- **Debug Panel**: Use VS Code debug panel for breakpoints and inspection
