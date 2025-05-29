#!/bin/bash

# Kill existing Pico-8 instance
pkill -f pico8
sleep 0.2

# Directory of the currently open file
DIR="$1"

# Find the only .p8 file in the directory
P8_FILE=$(find "$DIR" -maxdepth 1 -name '*.p8' | head -n 1)

# Path to Pico-8 binary — adjust as needed
PICO8="/Applications/PICO-8.app/Contents/MacOS/pico8"

# Run it
if [ -n "$P8_FILE" ]; then
  "$PICO8" -run "$P8_FILE"
else
  echo "No .p8 file found in $DIR"
  exit 1
fi