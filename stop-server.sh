#!/bin/bash

echo "🛑 Stopping Laravel Server..."
echo "=============================="

# Find and kill PHP processes on port 8000
PID=$(lsof -ti:8000)

if [ -z "$PID" ]; then
    echo "ℹ️  No server running on port 8000"
    exit 0
fi

echo "Found server process: $PID"
kill -9 $PID

sleep 1

# Verify it stopped
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    echo "❌ Failed to stop server"
    exit 1
else
    echo "✅ Server stopped successfully"
fi
