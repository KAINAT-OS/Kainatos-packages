#!/bin/bash
# Directory to store .desktop entries
desktop_dir="/computer"
ICON="drive-harddisk"

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
    used_char="█"
    free_char="░"
    bar=""

    for ((i = 0; i < used_bar_count; i++)); do
        bar+="${used_char}"
    done

    for ((i = 0; i < free_bar_count; i++)); do
        bar+="${free_char}"
    done


    #Warning
    #Warning
    if [ "$used_percent_number" -ge 90 ]; then
        ICON="dialog-warning"
        warning="[! LOW SPACE ]"
    else
        warning=""
        ICON="drive-harddisk"
    fi
    if [ "$used_percent_number" -ge 100 ]; then
        warning="[ ! DISK IS FULL]"
        ICON="dialog-error"

    fi

    # Build filename including ASCII bar
    filename="${drive_label}    [ ${free_space} free | ${total_space} ] ⎥${bar}⎢   ${warning}"

    # Desktop file
    desktop_file="${desktop_dir}/${filename}"
    cat << ENTRY > "${desktop_file}"
[Desktop Entry]
Type=Link
Name=${drive_label} [${free_space}|${total_space}] [${bar}] ${fs_useperc}
Icon=$ICON
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
used_char="█"
free_char="░"
bar=""

for ((i = 0; i < used_bar_count; i++)); do
    bar+="${used_char}"
done

for ((i = 0; i < free_bar_count; i++)); do
    bar+="${free_char}"
done


    #Warning
    if [ "$used_percent_number" -ge 90 ]; then
        ICON="dialog-warning"
        warning="[! LOW SPACE ]"
    else
        warning=""
        ICON="user-home"
    fi
    if [ "$used_percent_number" -ge 100 ]; then
        warning="[ ! DISK IS FULL]"
        ICON="dialog-error"

    fi
# Build home filename including ASCII bar
home_filename="${home_label}    [ ${home_avail} free | ${home_total} ]  ⎥${bar}⎢ ${warning}"

home_desktop_file="${desktop_dir}/${home_filename}"
cat << ENTRY > "${home_desktop_file}"
[Desktop Entry]
Type=Link
Name=${home_label} [${home_avail}|${home_total}] [${bar}] ${home_useperc}
Icon=$ICON
URL=file://${HOME}
Terminal=false
ENTRY

chmod +x "${home_desktop_file}"


# 3) Unmounted block devices
# -----------------------------
# Find all block partitions without a mountpoint
declare -a unmounted_devices=($(lsblk -pnlo NAME,TYPE,MOUNTPOINT | awk '$2=="part" && $3=="" {print $1}'))
for device in "${unmounted_devices[@]}"; do
    # Determine label or fallback to device name
    dev_label=$(lsblk -no LABEL "$device")
    dev_label="${dev_label:-$(basename "$device")}"
    echo $dev_label

    # Get total size
    total_size=$(lsblk -dnlo SIZE "$device")
    # Since unmounted, used and avail are unknown; assume 0% used
    free_space="N/A"
    used_percent_number=0
    fs_useperc="0%"

    # Build usage bar (all free)
    bar_length=10
    used_bar_count=0
    free_bar_count=$bar_length
    used_char="█"
    free_char="░"
    bar=""
    for ((i = 0; i < used_bar_count; i++)); do
        bar+="$used_char"
    done
    for ((i = 0; i < free_bar_count; i++)); do
        bar+="$free_char"
    done

    # Warning/icon logic (no space used -> no warning)
    ICON="disk-quota-critical"
    warning="⚠️ unmounted click to mount"

    # Build filename including size and bar
    umount_filename="${dev_label} [ Unknown free | unknowin ]${warning}"
    umount_desktop_file="${desktop_dir}/${umount_filename}"
cat << ENTRY > "${umount_desktop_file}"
[Desktop Entry]
Type=Application
Name=${dev_label} [${free_space}|${total_size}] [${bar}] ${fs_useperc}
Icon=$ICON
Exec=udisksctl mount -b ${device} && ${0}
Terminal=false
ENTRY
    chmod +x "${umount_desktop_file}"
done

echo "Desktop entries for mounted and unmounted drives created in ${desktop_dir}."
