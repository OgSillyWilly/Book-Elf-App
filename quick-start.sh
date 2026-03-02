#!/bin/bash
cd /Users/silkedelvaux/Herd/bookshelf_app

echo "📚 Boekenkast App - Quick Start"
echo "==============================="
echo ""
echo "Kies een platform:"
echo "1) Chrome (web browser)"
echo "2) iPhone (via USB)"
echo "3) Lijst alle devices"
echo ""
read -p "Keuze (1-3): " choice

case $choice in
  1)
    echo ""
    echo "🚀 Starting in Chrome..."
    echo "De app opent op: http://localhost:8080"
    echo ""
    echo "⚡ Hot reload: Druk 'r' in terminal"
    echo "🔄 Hot restart: Druk 'R' in terminal"
    echo "❌ Stoppen: Druk 'q' in terminal"
    echo ""
    flutter run -d chrome --web-port=8080
    ;;
  2)
    echo ""
    echo "📱 Starting on iPhone..."
    echo "Zorg ervoor dat:"
    echo "  • iPhone verbonden is via USB"
    echo "  • iPhone is trusted (popup bij eerste keer)"
    echo "  • Development certificate trusted in iPhone settings"
    echo ""
    echo "💡 Tip: Hot reload werkt ook via USB!"
    echo ""
    echo "⚡ Hot reload: Druk 'r' in terminal"
    echo "🔄 Hot restart: Druk 'R' in terminal"
    echo "❌ Stoppen: Druk 'q' in terminal"
    echo ""
    flutter run
    ;;
  3)
    echo ""
    echo "📱 Beschikbare devices:"
    flutter devices
    echo ""
    echo "Om op een specifiek device te runnen:"
    echo "  flutter run -d <device-id>"
    ;;
  *)
    echo "❌ Ongeldige keuze"
    exit 1
    ;;
esac
