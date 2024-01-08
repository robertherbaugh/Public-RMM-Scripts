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
        echo "Not Installed"
    fi
}

# Function to get the latest available version of Chrome
get_latest_version() {
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
install_or_update_chrome() {
    current_version=$(get_installed_version)
    latest_version=$(get_latest_version)
    echo "Current Version: $current_version"
    echo "Latest Version: $latest_version"

    # Compare current and latest version, install or update if necessary
    if [ "$current_version" != "$latest_version" ]; then
        echo "Installing or updating Chrome to latest version..."
        download_url="https://dl.google.com/chrome/mac/stable/accept_tos%3Dhttps%253A%252F%252Fwww.google.com%252Fintl%252Fen_ph%252Fchrome%252Fterms%252F%26_and_accept_tos%3Dhttps%253A%252F%252Fpolicies.google.com%252Fterms/googlechrome.pkg"
        echo "Downloading Chrome from: $download_url"
        curl -o "$temp_pkg" "$download_url" || { echo "Failed to download Chrome"; exit 1; }

        # Check if the downloaded file is a proper PKG
        if [ ! -s "$temp_pkg" ]; then
            echo "Downloaded file is not a valid PKG or is empty."
            exit 1
        fi

        echo "Installing the PKG..."
        sudo installer -pkg "$temp_pkg" -target / || { echo "Failed to install Chrome"; exit 1; }

        # Remove the temporary file
        rm "$temp_pkg" || { echo "Failed to remove the temporary file"; exit 1; }

        # Verify installation
        updated_version=$(get_installed_version)
        if [ "$updated_version" == "$latest_version" ]; then
            echo "Chrome has been installed/updated to version $latest_version."
        else
            echo "Installation/Update failed. Expected version $latest_version but found $updated_version."
            exit 1
        fi
    else
        echo "No update necessary. The latest version of Chrome is already installed."
    fi
}

# Execute the installation/update function
install_or_update_chrome
