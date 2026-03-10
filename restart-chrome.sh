#!/bin/bash

# Stop Flutter Chrome app
echo "🛑 Stoppen Flutter app..."
pkill -f "flutter.*chrome" 2>/dev/null
sleep 1

# Sluit alle Chrome instanties die Flutter gebruikt
echo "🔴 Sluiten Chrome..."
pkill -f "flutter_tools_chrome_device" 2>/dev/null
sleep 1

# Clean Flutter caches
echo "🧹 Clearing Flutter web cache..."
rm -rf build/web 2>/dev/null
flutter clean > /dev/null 2>&1

echo ""
echo "✅ Klaar! Start nu opnieuw met:"
echo "   ./start-chrome.sh"
echo ""
echo "   OF"
echo ""
echo "   flutter run -d chrome"
