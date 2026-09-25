#!/bin/zsh
# Genera il progetto, compila e lancia sul simulatore.
# Uso: ./build.sh [UDID]   (default: primo iPhone avviato, altrimenti iPhone 16 Pro)
set -e
cd "$(dirname "$0")"
UDID=${1:-$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)}
UDID=${UDID:-966CB762-2AF8-4516-87DC-C47EE9431150}
# DerivedData fuori dal Desktop: iCloud aggiunge attributi che fanno fallire la firma.
DD=~/Library/Developer/Xcode/DerivedData/Interviews
xcodegen generate -q
xcodebuild -project Interviews.xcodeproj -scheme Interviews -sdk iphonesimulator \
  -destination "id=$UDID" -derivedDataPath $DD build -quiet
xcrun simctl boot $UDID 2>/dev/null || true
xcrun simctl install $UDID $DD/Build/Products/Debug-iphonesimulator/Interviews.app
xcrun simctl launch $UDID com.cldnpl.interviews
