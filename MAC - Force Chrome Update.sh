#!/bin/bash

# Define the location of Chrome
chrome_app="/Applications/Google Chrome.app"
info_plist="$chrome_app/Contents/Info.plist"

# Function to get the installed version of Chrome
get_installed_version() {
    if [ -f "$info_plist" ]; then
        /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${info_plist}"
    else
        echo "Not Installed"
    fi
}

# Function to get the latest available version of Chrome
get_latest_version() {
    get_latest_version() {
    # Make a GET request to the API endpoint for macOS
    response=$(curl -s "https://versionhistory.googleapis.com/v1/chrome/platforms/mac/channels/stable/versions")

    # Parse the response using grep and awk to extract the version number
    # This approach assumes that the version field is on a single line and is the first "version" field in the response
    latest_version=$(echo "$response" | grep -o '"version": "[^"]*' | grep -o '[0-9.]*' | head -1)

    echo "$latest_version"
    }
}

# Function to prompt the user to restart Chrome
prompt_restart_chrome() {
    osascript -e 'tell app "System Events" to display dialog "Google Chrome needs to be restarted to complete the update. Restart now?" buttons {"Restart Chrome"} default button "Restart"'
    osascript -e 'tell application "Google Chrome" to quit'
    sleep 2 # Wait for the application to quit
    open -a "Google Chrome"
}

# Check if Google Chrome is installed
current_version=$(get_installed_version)
if [ "$current_version" == "Not Installed" ]; then
    echo "Google Chrome not installed."
    exit 0
fi

# Get the latest version of Chrome
latest_version=$(get_latest_version)

echo "Current Version: $current_version"
echo "Latest Version: $latest_version"

# Compare the two versions and update if necessary
if [ "$current_version" != "$latest_version" ]; then
    echo "Updating Google Chrome..."

    # Download the latest version
    # Normally, this would be the URL to the Chrome download
    download_url="https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"

    # Define a temporary file for the download
    echo "Downloading the latest version from: $download_url"
    temp_dmg="/tmp/googlechrome.dmg"

    # Download the latest version
    echo "Downloading the latest version..."
    curl -o "$temp_dmg" "$download_url"

    # Mount the DMG and store the volume name
    volume=$(hdiutil attach "$temp_dmg" | grep "Volumes/Google Chrome" | awk '{print $3}')
    
    # Now that we have the correct volume path, let's construct the path to the app within the mounted volume
    app_path="$volume/Google Chrome.app"
    
    # Check if the app path exists before trying to copy
    if [ -d "$app_path" ]; then
        # Remove the old version
        echo "Removing the old version..."
        rm -rf "$chrome_app"
    
        # Copy the new version
        echo "Copying the new version from $app_path to /Applications..."
        cp -R "$app_path" /Applications/
    else
        echo "Failed to find the mounted Google Chrome.app. Update cannot proceed."
        # Unmount the volume if it's mounted
        if [ -d "$volume" ]; then
            hdiutil detach "$volume"
        fi
        exit 1
    fi
    
    # Unmount the volume
    echo "Unmounting the DMG..."
    hdiutil detach "$volume"
    
    # Remove the temporary file
    echo "Removing the temporary file..."
    rm "$temp_dmg"

    # Check if the update was successful
    updated_version=$(get_installed_version)
    echo "New Version: $updated_version"
    if [ "$updated_version" == "$latest_version" ]; then
        echo "Update successful. Latest Google Chrome version installed."
        # Prompt to restart Chrome
        # Uncomment the line below if you wish to prompt the user to restart chrome (this is untested ATM)
        #prompt_restart_chrome
    else
        echo "Update failed. The version installed is still $updated_version."
    fi
else
    echo "No update necessary. The latest version of Google Chrome is already installed."
fi
