#!/bin/bash
# Directory to store .desktop entries
DESKTOP_DIR="/computer"
# Clean old entries
rm -f "$DESKTOP_DIR"/*.desktop

# Loop through mounted drives and create .desktop files with free space
while read -r mount_point fs_size fs_used fs_avail fs_useperc fs_type; do
    [ -z "$mount_point" ] && continue
    # Exclude system partitions like /boot, /proc, /sys, etc.
    if [[ "$mount_point" =~ ^/(boot|proc|sys|dev|run|tmp|var/lib/docker|snap) ]]; then
        continue
    fi
    # Retrieve the device associated with the mount point
    device=$(findmnt -n -o SOURCE "$mount_point")
    # Retrieve the label of the device
    drive_label=$(lsblk -no LABEL "$device")
    # Use the device name if no label is found
    drive_label="${drive_label:-$(basename "$mount_point")}"
    desktop_file="$DESKTOP_DIR/${drive_label}_(${fs_avail}_free)-drive.desktop"
    # Format free space (fs_avail)
    free_space="$fs_avail"
    cat << ENTRY > "$desktop_file"
[Desktop Entry]
Type=Link
Name=${drive_label} (${free_space} free)
Icon=drive-harddisk
URL=file://$mount_point
Terminal=false
MimeType=application/x-desktop;application/x-drive-desktop;

ENTRY
    chmod +x "$desktop_file"
done < <(df -h --output=target,size,used,avail,pcent,fstype | tail -n +2)

echo "Desktop entries for mounted drives created in $DESKTOP_DIR."

# Create a .desktop entry for the $HOME directory
home_label="Home"
home_avail=$(df -h "$HOME" --output=avail | tail -n 1 | xargs)
home_desktop_file="$DESKTOP_DIR/${home_label}_(${home_avail}_free)-drive.desktop"

cat << ENTRY > "$home_desktop_file"
[Desktop Entry]
Type=Link
Name=${home_label} (${home_avail} free)
Icon=user-home
URL=file://$HOME
Terminal=false
MimeType=application/x-desktop;application/x-drive-desktop;

ENTRY

chmod +x "$home_desktop_file"
