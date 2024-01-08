#!/bin/bash

# Define the location of Firefox
firefox_app="/Applications/Firefox.app"
info_plist="$firefox_app/Contents/Info.plist"

# Function to get the installed version of Firefox
get_installed_version() {
    if [ -f "$info_plist" ]; then
        installed_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${info_plist}")
        echo "$installed_version"
    else
        echo ""  # Return empty string to indicate not installed
    fi
}

# Function to get the latest available version of Firefox
get_latest_version() {
    # Ensure curl is installed
    if ! command -v curl &> /dev/null; then
        echo "curl could not be found. Please install curl."
        exit 1
    fi

    # Fetch the latest version of Firefox from the URL
    latest_version=$(curl -s "https://product-details.mozilla.org/1.0/firefox_versions.json" | grep 'LATEST_FIREFOX_VERSION' | sed -E 's/.*: "([0-9\.]+)".*/\1/')
    if [ -z "$latest_version" ]; then
        echo "Failed to fetch the latest version"
        exit 1
    fi
    echo "$latest_version"
}

# Function to install or update Firefox using .pkg
version_check() {
    current_version=$(get_installed_version)
    latest_version=$(get_latest_version)
    echo "Current Version: $current_version"
    echo "Latest Version: $latest_version"

    # Check if Firefox is not installed or up to date
    if [ -z "$current_version" ] || [ "$current_version" == "$latest_version" ]; then
        echo "Up to date/Not Installed"
    else
        echo "Out of date"
    fi
}

# Main Section
version_check
