#!/bin/bash

# Constants
firefox_app="/Applications/Firefox.app"
info_plist="$firefox_app/Contents/Info.plist"
temp_pkg="/tmp/firefox.pkg"

# Function to get the installed version of Firefox
get_installed_version() {
    if [ -f "$info_plist" ]; then
        installed_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${info_plist}")
        echo "$installed_version"
    else
        echo "Not Installed"
    fi
}

# Function to get the latest available version of Firefox
get_latest_version() {
    latest_version=$(curl -s "https://product-details.mozilla.org/1.0/firefox_versions.json" | grep 'LATEST_FIREFOX_VERSION' | sed -E 's/.*: "([0-9\.]+)".*/\1/')
    if [ -z "$latest_version" ]; then
        echo "Failed to fetch the latest version"
        exit 1
    fi
    echo "$latest_version"
}

# Function to install Firefox
install_firefox() {
    latest_version=$(get_latest_version)
    download_url="https://ftp.mozilla.org/pub/firefox/releases/$latest_version/mac/en-US/Firefox%20$latest_version.pkg"
    echo "Downloading Firefox from: $download_url"
    curl -o "$temp_pkg" "$download_url" || { echo "Failed to download Firefox"; exit 1; }

    # Check if the downloaded file is a proper PKG
    if [ ! -s "$temp_pkg" ]; then
        echo "Downloaded file is not a valid PKG or is empty."
        exit 1
    fi

    echo "Installing the PKG..."
    sudo installer -pkg "$temp_pkg" -target / || { echo "Failed to install Firefox"; exit 1; }

    # Remove the temporary file
    rm "$temp_pkg" || { echo "Failed to remove the temporary file"; exit 1; }

    # Verify installation
    updated_version=$(get_installed_version)
    if [ "$updated_version" == "$latest_version" ]; then
        echo "Firefox has been installed/updated to version $latest_version."
    else
        echo "Installation/Update failed. Expected version $latest_version but found $updated_version."
        exit 1
    fi
}

# Function to install or update Firefox using .pkg
install_or_update_firefox() {
    current_version=$(get_installed_version)
    latest_version=$(get_latest_version)
    echo "Current Version: $current_version"
    echo "Latest Version: $latest_version"

    # Compare current and latest version, install or update if necessary
    if [ "$current_version" != "$latest_version" ]; then
        echo "Installing or updating Firefox to latest version..."
        install_firefox
    else
        echo "No update necessary. The latest version of Firefox is already installed."
    fi
}

# Execute the installation/update function
install_or_update_firefox
