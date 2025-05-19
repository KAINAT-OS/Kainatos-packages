#!/bin/bash

# Directory to store disk links
DISK_DIR="$HOME/.disks"

# Create the directory if it doesn't exist
mkdir -p "$DISK_DIR"

# Remove any existing links to avoid duplication
rm -f "$DISK_DIR"/*

# Loop through all mounted drives
for mount_point in $(lsblk -lnpo MOUNTPOINT | grep -v '^$'); do
    # Extract the drive name from the mount point
    drive_name=$(basename "$mount_point")
    # Create a symbolic link in the .disks directory
    ln -sf "$mount_point" "$DISK_DIR/$drive_name"
done

echo "Links to mounted drives have been created in $DISK_DIR."
