#!/bin/bash

# Constants
chrome_app="/Applications/Google Chrome.app"
info_plist="$chrome_app/Contents/Info.plist"
temp_pkg="/tmp/googlechrome.pkg"

# Function to get the installed version of Chrome
get_installed_version() {
    if [ -f "$info_plist" ]; then
        installed_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${info_plist}")
        echo "$installed_version"
    else
        echo ""  # Return empty string to indicate not installed
    fi
}

# Function to get the latest available version of Chrome
get_latest_version() {
    # Ensure curl is installed
    if ! command -v curl &> /dev/null; then
        echo "curl could not be found. Please install curl."
        exit 1
    fi

    # Make a GET request to the API endpoint for macOS
    response=$(curl -s "https://versionhistory.googleapis.com/v1/chrome/platforms/mac/channels/stable/versions")
    
    # Parse the response using grep and awk to extract the version number
    latest_version=$(echo "$response" | grep -o '"version": "[^"]*' | grep -o '[0-9.]*' | head -1)

    if [ -z "$latest_version" ]; then
        echo "Failed to fetch the latest version"
        exit 1
    fi
    echo "$latest_version"
}

# Function to install or update Chrome using .pkg
version_check() {
    current_version=$(get_installed_version)
    latest_version=$(get_latest_version)
    #echo "Current Version: $current_version"
    #echo "Latest Version: $latest_version"

    # Check if Chrome is not installed or up to date
    if [ -z "$current_version" ] || [ "$current_version" == "$latest_version" ]; then
        echo "Up to date/Not Installed"
    else
        echo "Out of date"
    fi
}

# Main Section
version_check
