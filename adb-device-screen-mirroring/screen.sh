#!/bin/bash

# Script: screen.sh
# Description: Installs ADB and scrcpy offline, restores ADB keys, and mirrors the screen via USB.
# Usage: ./screen.sh

# Error handling
set -e  # Exit on error
trap "echo 'Script failed at step: $LINENO'; exit 1" ERR

# Variables
DEB_DIR="/path/to/android-offline"  # Directory containing .deb files
ADB_BACKUP_DIR="$HOME/adb-backup"  # Directory for ADB key backup
ADB_KEY_DIR="$HOME/.android"       # ADB key storage directory

# Step 1: Install ADB and scrcpy from local .deb files
install_packages() {
    echo "Installing ADB and scrcpy from local .deb files..."
    if [ -d "$DEB_DIR" ]; then
        sudo dpkg -i "$DEB_DIR"/*.deb >/dev/null 2>&1 || {
            echo "Failed to install packages. Check if .deb files exist in $DEB_DIR."
            exit 1
        }
        echo "Packages installed successfully."
    else
        echo "Directory $DEB_DIR not found. Please ensure the .deb files are available."
        exit 1
    fi
}

# Step 2: Restore ADB keys (if available)
restore_adb_keys() {
    echo "Restoring ADB keys..."
    if [ -d "$ADB_BACKUP_DIR" ]; then
        mkdir -p "$ADB_KEY_DIR"
        cp "$ADB_BACKUP_DIR"/adbkey* "$ADB_KEY_DIR/" 2>/dev/null || {
            echo "No ADB keys found in backup directory. New keys will be generated."
        }
        chmod 600 "$ADB_KEY_DIR"/adbkey* 2>/dev/null || {
            echo "Failed to set permissions for ADB keys."
        }
        echo "ADB keys restored successfully."
    else
        echo "ADB key backup directory not found. New keys will be generated."
    fi
}

# Step 3: Start ADB server and mirror screen
start_adb_and_mirror() {
    echo "Starting ADB server..."
    adb kill-server >/dev/null 2>&1 || {
        echo "Failed to kill ADB server."
        exit 1
    }
    adb start-server >/dev/null 2>&1 || {
        echo "Failed to start ADB server. Ensure USB debugging is enabled on the device."
        exit 1
    }

    # Get device serial number
    SERIAL=$(adb devices | grep -oP '^\S+' | head -n 1)
    if [ -z "$SERIAL" ]; then
        echo "No device found. Ensure the device is connected via USB and USB debugging is enabled."
        exit 1
    fi

    echo "Device connected: $SERIAL"
    echo "Mirroring screen via USB (no audio)..."
    scrcpy --serial "$SERIAL" --no-audio || {
        echo "Failed to start scrcpy. Ensure scrcpy is installed and the device is authorized."
        exit 1
    }
}

# Main function
main() {
    echo "Starting offline ADB and scrcpy setup..."
    install_packages
    restore_adb_keys
    start_adb_and_mirror
    echo "Setup complete! Screen mirroring should now be active."
}

# Run the script
main


