#!/bin/bash
# Directory to store .desktop entries
desktop_dir="/computer"

# Clean old entries
rm -f "${desktop_dir}"/*

# Loop through mounted drives and create .desktop files with free|total space, visual bar in name and filename
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

    # Usage bar
    used_percent_number=${fs_useperc%%%}  # Remove % sign
    bar_length=10
    used_bar_count=$((used_percent_number * bar_length / 100))
    free_bar_count=$((bar_length - used_bar_count))
    bar="$(printf '%*s' "${used_bar_count}" '' | tr ' ' '#')"
    bar+="$(printf '%*s' "${free_bar_count}" '' | tr ' ' '.')"

    #Warning
    #Warning
    if [ "$used_percent_number" -ge 90 ]; then
        warning="[ [⚠️] LOW SPACE ]"
    else
        warning=""
    fi
    if [ "$used_percent_number" -ge 100 ]; then
        warning="[ [⛔] DISK IS FULL]"

    fi

    # Build filename including ASCII bar
    filename="${drive_label}    [ ${free_space} free | ${total_space}]  [${bar}]    ${warning}"

    # Desktop file
    desktop_file="${desktop_dir}/${filename}"
    cat << ENTRY > "${desktop_file}"
[Desktop Entry]
Type=Link
Name=${drive_label} [${free_space}|${total_space}] [${bar}] ${fs_useperc}
Icon=drive-harddisk
URL=file://${mount_point}
Terminal=false
ENTRY
    chmod +x "${desktop_file}"
done < <(df -h --output=target,size,used,avail,pcent,fstype | tail -n +2)

echo "Desktop entries for mounted drives created in ${desktop_dir}."

# .desktop for $HOME with free|total, visual bar in name and filename
home_label="Home"
home_info=$(df -h "$HOME" --output=size,used,avail,pcent | tail -n 1)
home_total=$(awk '{print $1}' <<< "${home_info}")
home_used=$(awk '{print $2}' <<< "${home_info}")
home_avail=$(awk '{print $3}' <<< "${home_info}")
home_useperc=$(awk '{print $4}' <<< "${home_info}")

used_percent_number=${home_useperc%%%}
bar_length=10
used_bar_count=$((used_percent_number * bar_length / 100))
free_bar_count=$((bar_length - used_bar_count))
bar="$(printf '%*s' "${used_bar_count}" '' | tr ' ' '#')"
bar+="$(printf '%*s' "${free_bar_count}" '' | tr ' ' '.')"

    #Warning
    if [ "$used_percent_number" -ge 90 ]; then
        warning="[ [⚠️] LOW SPACE ]"
    else
        warning=""
    fi
    if [ "$used_percent_number" -ge 100 ]; then
        warning="[ [⛔] DISK IS FULL]"

    fi
# Build home filename including ASCII bar
home_filename="${home_label}    [ ${home_avail} free | ${home_total} ]  [ ${bar} ]  ${warning}"

home_desktop_file="${desktop_dir}/${home_filename}"
cat << ENTRY > "${home_desktop_file}"
[Desktop Entry]
Type=Link
Name=${home_label} [${home_avail}|${home_total}] [${bar}] ${home_useperc}
Icon=user-home
URL=file://${HOME}
Terminal=false
ENTRY

chmod +x "${home_desktop_file}"
