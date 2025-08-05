#!/bin/bash

# 🍎 TripMate iOS Quick Setup Script for Mac
# Run this script on your Mac after transferring the project

echo "🍎 Setting up TripMate for iOS development..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first:"
    echo "   https://docs.flutter.dev/get-started/install/macos"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from App Store"
    exit 1
fi

# Check if CocoaPods is installed
if ! command -v pod &> /dev/null; then
    echo "📦 Installing CocoaPods..."
    sudo gem install cocoapods
fi

echo "✅ Prerequisites check complete"

# Navigate to project directory (adjust path as needed)
echo "📁 Make sure you're in the TripMate project directory"

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Install iOS pods
echo "🍎 Installing iOS dependencies..."
cd ios
pod install
cd ..

# Run Flutter doctor
echo "🔍 Checking Flutter setup..."
flutter doctor

echo ""
echo "🎉 Setup complete! Now you can:"
echo "   1. Open iOS Simulator: open -a Simulator"
echo "   2. Run on simulator: flutter run -d ios"
echo "   3. Connect iPhone and run: flutter run"
echo ""
echo "📍 Your TripMate app includes:"
echo "   ✅ GPS location tracking (works offline)"
echo "   ✅ Offline maps with cached tiles"
echo "   ✅ Local data storage with Hive"
echo "   ✅ iOS location permissions configured"
