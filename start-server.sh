#!/bin/bash

echo "🚀 Starting Laravel Backend Server..."
echo "======================================"
echo ""

# Check if server is already running
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    echo "✅ Server is already running on port 8000"
    echo ""
    echo "Om te stoppen: killall php"
    echo "Of gebruik: lsof -ti:8000 | xargs kill -9"
    exit 0
fi

# Start server in background
cd /Users/silkedelvaux/Herd/showcase

echo "Starting server at http://127.0.0.1:8000"
echo "API endpoint: http://127.0.0.1:8000/api"
echo ""
echo "💡 Tips:"
echo "  - Server draait op de achtergrond"
echo "  - Check status: ./check-server.sh"
echo "  - Stoppen: killall php"
echo ""

# Start in background with nohup
nohup php artisan serve --host=0.0.0.0 --port=8000 > /tmp/laravel-server.log 2>&1 &

# Give it a moment to start
sleep 2

# Check if it started successfully
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    echo "✅ Server started successfully!"
    echo ""
    echo "Logs: tail -f /tmp/laravel-server.log"
else
    echo "❌ Failed to start server"
    echo ""
    echo "Check logs: cat /tmp/laravel-server.log"
    exit 1
fi
