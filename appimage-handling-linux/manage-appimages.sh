#!/bin/bash

# Set paths
APPIMAGE_DIR="$HOME/AppImages"
DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
DOWNLOADS_DIR="$HOME/Downloads"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
DEFAULT_ICON="$APPIMAGE_DIR/cursor.png"  # Default fallback icon

# Ensure directories exist
mkdir -p "$APPIMAGE_DIR" "$DESKTOP_ENTRY_DIR" "$ICON_DIR"

# Ensure the default icon exists
if [ ! -f "$DEFAULT_ICON" ]; then
    echo "⚠️ Default icon not found! Please make sure cursor.png is available in $APPIMAGE_DIR."
    exit 1
fi

# Define locations to scan for AppImages
SEARCH_DIRS=("$DOWNLOADS_DIR" "$HOME/Desktop")

# Function to move AppImages to ~/AppImages/
move_appimages() {
    echo "🔍 Scanning for new AppImages in Downloads and other locations..."
    for dir in "${SEARCH_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -maxdepth 1 -type f -iname "*.AppImage" | while read -r file; do
                filename=$(basename "$file")
                target="$APPIMAGE_DIR/$filename"

                if [ -f "$target" ]; then
                    echo "⚠️  $filename already exists! Updating..."
                    mv "$file" "$target.new" && mv "$target" "$target.old" && mv "$target.new" "$target"
                    echo "✅ Updated $filename in $APPIMAGE_DIR/"
                else
                    mv "$file" "$APPIMAGE_DIR/"
                    echo "✅ Moved $filename to $APPIMAGE_DIR/"
                fi
                chmod +x "$APPIMAGE_DIR/$filename"
            done
        fi
    done
}

# Function to handle sandbox permissions
handle_sandbox_permissions() {
    echo "🔒 Fixing sandbox permissions..."
    for appimage in "$APPIMAGE_DIR"/*.AppImage; do
        [ -f \"$appimage\" ] || continue

        # Extract the AppImage to access files
        \"$appimage\" --appimage-extract >/dev/null 2>&1

        # Fix permissions for chrome-sandbox
        if [ -f squashfs-root/chrome-sandbox ]; then
            sudo chown root:root squashfs-root/chrome-sandbox
            sudo chmod 4755 squashfs-root/chrome-sandbox
            echo \"✅ Fixed permissions for chrome-sandbox in $appimage\"
        fi

        # Clean up extracted files
        rm -rf squashfs-root

        "$appimage" --appimage-extract >/dev/null 2>&1

        if [ -f squashfs-root/chrome-sandbox ]; then
            sudo chown root:root squashfs-root/chrome-sandbox
            sudo chmod u+s squashfs-root/chrome-sandbox
            echo "✅ Fixed permissions for chrome-sandbox in $appimage"
        fi

        rm -rf squashfs-root
    done
}

# Function to create .desktop entries
create_desktop_entry() {
    echo "🔧 Creating application menu entries..."
    for appimage in "$APPIMAGE_DIR"/*.AppImage; do
        [ -f "$appimage" ] || continue

        filename=$(basename "$appimage")
        name="${filename%.*}"
        desktop_file="$DESKTOP_ENTRY_DIR/$name.desktop"

        if [ -f "$desktop_file" ]; then
            echo "ℹ️  Desktop entry for $name already exists. Skipping."
            continue
        fi

        # Extract icon from AppImage (fallback to default icon)
        "$appimage" --appimage-extract >/dev/null 2>&1
        extracted_icon=$(find squashfs-root -iname '*.png' -type f | head -n1)
        icon="$ICON_DIR/$name.png"

        if [ -n "$extracted_icon" ]; then
            mv "$extracted_icon" "$icon"
        else
            icon="$DEFAULT_ICON"
        fi
        rm -rf squashfs-root

        # Create the desktop entry
        cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Exec=$appimage
Icon=$icon
Terminal=false
Categories=Application;
EOF

        chmod +x "$desktop_file"
        echo "✅ Created menu entry for $name"
    done
}

# Function to verify AppImages
verify_appimages() {
    echo "🔎 Verifying AppImages for sandbox issues..."
    for appimage in "$APPIMAGE_DIR"/*.AppImage; do
        [ -f "$appimage" ] || continue
        "$appimage" --appimage-version >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "❌ WARNING: $appimage may not run correctly!"
        fi
    done
}

# Function to clean up old backups
cleanup_old_backups() {
    echo "🧹 Cleaning up old backups..."
    find "$APPIMAGE_DIR" -name '*.old' -mtime +30 -delete
}

# Function to update desktop entries
update_desktop_database() {
    echo "🔄 Updating desktop entries..."
    update-desktop-database "$DESKTOP_ENTRY_DIR"
    echo "✅ Desktop database updated!"
}

# Main script execution
move_appimages
handle_sandbox_permissions
verify_appimages
create_desktop_entry
cleanup_old_backups
update_desktop_database

echo "✅ All AppImages are now managed, verified, and available in the application menu!"
