#!/bin/bash

echo "📱 Starting Flutter app on iPhone Simulator..."
echo ""

# Check if simulator is running
running_sim=$(xcrun simctl list devices | grep Booted | grep iPhone | head -1)

if [ -z "$running_sim" ]; then
    echo "⚠️  Geen simulator draait momenteel"
    echo "🚀 iPhone 16e simulator starten..."
    open -a Simulator
    sleep 5
    xcrun simctl boot 5BA237D2-C71E-47DD-BFFA-DC92BA01D199 2>/dev/null || true
    sleep 3
fi

echo "✅ Simulator is klaar"
echo ""
echo "🔨 App bouwen en starten..."
echo ""

flutter run -d 5BA237D2-C71E-47DD-BFFA-DC92BA01D199
