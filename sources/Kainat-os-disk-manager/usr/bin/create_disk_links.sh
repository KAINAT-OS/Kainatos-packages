#!/bin/bash
# Directory to store .desktop entries
DESKTOP_DIR="$HOME/.disks"
mkdir -p "$DESKTOP_DIR"
# Clean old entries
rm -f "$DESKTOP_DIR"/*.desktop

# Loop through mounted drives and create .desktop files with free space
while read -r mount_point fs_size fs_used fs_avail fs_useperc fs_type; do
    [ -z "$mount_point" ] && continue
    drive_name=$(basename "$mount_point")
    desktop_file="$DESKTOP_DIR/${drive_name}.desktop"
    # Format free space (fs_avail)
    free_space="$fs_avail"
    cat << ENTRY > "$desktop_file"
[Desktop Entry]
Type=Application
Name=${drive_name} (${free_space} free)
Icon=drive-harddisk
Exec=xdg-open file://$mount_point
Terminal=false
ENTRY
    chmod +x "$desktop_file"
done < <(df -h --output=target,size,used,avail,pcent,fstype | tail -n +2)

echo "Desktop entries for mounted drives created in $DESKTOP_DIR."
