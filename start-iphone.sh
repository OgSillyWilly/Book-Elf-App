#!/bin/bash

echo "📱 Starting Flutter app on iPhone..."
echo ""
echo "⚠️  Zorg ervoor dat:"
echo "1. Je iPhone is aangesloten via USB"
echo "2. Je iPhone is 'trusted' in de instellingen"
echo "3. Developer Mode is ingeschakeld op je iPhone"
echo ""
echo "🌐 API URL voor iPhone: http://172.20.24.5:8000/api"
echo ""

# Check if iPhone is connected
echo "🔍 Zoeken naar iPhone..."
devices=$(flutter devices --machine | jq -r '.[] | select(.targetPlatform == "ios") | .id')

if [ -z "$devices" ]; then
    echo "❌ Geen iPhone gevonden!"
    echo ""
    echo "Verbind je iPhone via USB en probeer opnieuw."
    exit 1
fi

echo "✅ iPhone gevonden!"
echo ""
echo "🚀 App starten op iPhone..."
flutter run -d $(echo "$devices" | head -1)
