#!/bin/bash

echo "=== Flutter Build Fix Script ==="
echo "This script will fix the Dart language version issues"

echo "Step 1: Cleaning Flutter project..."
flutter clean

echo "Step 2: Removing old build artifacts..."
rm -rf build/
rm -rf .dart_tool/
rm -rf ios/Pods/
rm -rf ios/Podfile.lock

echo "Step 3: Getting dependencies..."
flutter pub get

echo "Step 4: Cleaning iOS build cache..."
cd ios && rm -rf build/ && cd ..

echo "Step 5: Running Flutter doctor..."
flutter doctor

echo "Step 6: Trying to build for iOS simulator..."
flutter build ios --simulator --debug

echo "=== If still failing, try these commands manually ==="
echo "1. flutter clean"
echo "2. flutter pub get"
echo "3. cd ios && rm -rf Pods Podfile.lock && pod install && cd .."
echo "4. flutter run"