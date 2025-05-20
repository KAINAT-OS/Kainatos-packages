#!/bin/bash
# Directory to store .desktop entries
desktop_dir="/computer"

# Clean old entries
rm -f "${desktop_dir}"/*.desktop

# Loop through mounted drives and create .desktop files with free/total space
while read -r mount_point fs_size fs_used fs_avail fs_useperc fs_type; do
    [ -z "${mount_point}" ] && continue

    # Exclude system partitions
    if [[ "${mount_point}" =~ ^/(boot|proc|sys|dev|run|tmp|var/lib/docker|snap) ]]; then
        continue
    fi

    # Device and label
    device=$(findmnt -n -o SOURCE "${mount_point}")
    drive_label=$(lsblk -no LABEL "${device}")
    drive_label="${drive_label:-$(basename "${mount_point}")}"  # fallback

    # Format spaces
    free_space="${fs_avail}"
    total_space="${fs_size}"

    # Desktop file
    desktop_file="${desktop_dir}/${drive_label}_[${free_space}/${total_space}].desktop"
    cat << ENTRY > "${desktop_file}"
[Desktop Entry]
Type=Link
Name=${drive_label} [${free_space}/${total_space}]
Icon=drive-harddisk
URL=file://${mount_point}
Terminal=false
ENTRY
    chmod +x "${desktop_file}"
done < <(df -h --output=target,size,used,avail,pcent,fstype | tail -n +2)

echo "Desktop entries for mounted drives created in ${desktop_dir}."

# .desktop for $HOME with free/total
home_label="Home"
home_info=$(df -h "$HOME" --output=size,avail | tail -n 1)
home_total=$(awk '{print $1}' <<< "${home_info}")
home_avail=$(awk '{print $2}' <<< "${home_info}")

home_desktop_file="${desktop_dir}/${home_label}_[${home_avail}/${home_total}].desktop"
cat << ENTRY > "${home_desktop_file}"
[Desktop Entry]
Type=Link
Name=${home_label} [${home_avail}/${home_total}]
Icon=user-home
URL=file://${HOME}
Terminal=false
ENTRY

chmod +x "${home_desktop_file}"
