#!/bin/bash

# Cache file to store last known location
CACHE_FILE="$HOME/.cache/sketchybar_location"
CACHE_MAX_AGE=1800 # 30 minutes in seconds

# Create cache directory if it doesn't exist
mkdir -p "$HOME/.cache"

# Check if cache exists and is fresh
if [ -f "$CACHE_FILE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -f %m "$CACHE_FILE")))
    if [ $CACHE_AGE -lt $CACHE_MAX_AGE ]; then
        # Cache is fresh, use it
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Get current location using CoreLocationCLI (default format is "lat lon" with space)
LOCATION=$(CoreLocationCLI -once 2>/dev/null | tr ' ' ',')

# Check if location was successfully retrieved
if [ -n "$LOCATION" ] && [ "$LOCATION" != "," ]; then
    # Save to cache
    echo "$LOCATION" > "$CACHE_FILE"
    echo "$LOCATION"
else
    # If location fails, check if we have cached location
    if [ -f "$CACHE_FILE" ]; then
        cat "$CACHE_FILE"
    else
        # Ultimate fallback: London coordinates
        echo "51.5074,-0.1278"
    fi
fi
