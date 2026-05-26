#!/bin/bash

# Move to the directory of this script
cd "$(dirname "$0")"

echo "==========================================="
echo "Building Hasana Documentation Website Data"
echo "==========================================="

python3 build.py

if [ $? -ne 0 ]; then
  echo "Error: Python build script failed!"
  exit 1
fi

echo ""
echo "==========================================="
echo "Starting local web server..."
echo "==========================================="
echo "You can open the website at:"
echo "👉  http://localhost:8000"
echo "==========================================="
echo "Press Ctrl+C to stop the server."
echo ""

python3 -m http.server 8000
