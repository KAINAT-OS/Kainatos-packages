#!/usr/bin/env bash
# Directory to store .desktop entries
desktop_dir="/computer"

# Clean old entries
rm -f "${desktop_dir}"/*

# Function to build a 10-character usage bar
build_bar() {
  local used_pct=$1
  local length=10
  local used_count=$(( used_pct * length / 100 ))
  local free_count=$(( length - used_count ))
  local s=""
  for ((i=0; i<used_count; i++)); do s+="█"; done
  for ((i=0; i<free_count; i++)); do s+="░"; done
  printf "%s" "$s"
}

# ── Mounted drives ──
df -h --output=target,size,used,avail,pcent,fstype | tail -n +2 | \
while IFS= read -r line; do
  [[ -z $line ]] && continue

  # split into words
  read -ra parts <<<"$line"
  n=${#parts[@]}
  # guard: we need at least 6 fields
  (( n < 6 )) && continue

  # pull off the last five fields
  fs_type=${parts[n-1]}
  fs_useperc=${parts[n-2]}
  fs_avail=${parts[n-3]}
  fs_used=${parts[n-4]}
  fs_size=${parts[n-5]}

  # the mount_point is everything before those five
  mount_point="${parts[0]}"
  for ((i=1; i<=n-6; i++)); do
    mount_point+=" ${parts[i]}"
  done

  # skip system mounts
  if [[ "$mount_point" =~ ^/(boot|proc|sys|dev|run|tmp|var/lib/docker|snap)($|/) ]]; then
    continue
  fi

  # get device and label
  device=$(findmnt -n -o SOURCE --target "$mount_point")
  drive_label=$(lsblk -no LABEL "$device")
  drive_label=${drive_label:-$(basename "$mount_point")}

  # build bar & choose icon/warning
  used_pct=${fs_useperc%%%}
  bar=$(build_bar "$used_pct")
  if (( used_pct >= 100 )); then
    ICON="dialog-error"; warning="[ ! DISK IS FULL ]"
  elif (( used_pct >= 90 )); then
    ICON="dialog-warning"; warning="[ ! LOW SPACE ]"
  else
    ICON="drive-harddisk";  warning=""
  fi

  # write .desktop
  filename="${drive_label}    [ ${fs_avail} free | ${fs_size} ] ⎥${bar}⎢   ${warning}"
  desktop_file="${desktop_dir}/${filename}"
  cat >"$desktop_file" <<ENTRY
[Desktop Entry]
Type=Link
Name=${drive_label} [${fs_avail}|${fs_size}] [${bar}] ${fs_useperc}
Icon=${ICON}
URL=file://${mount_point}
Terminal=false
ENTRY
  chmod +x "$desktop_file"
done

echo "Mounted-drive entries created in ${desktop_dir}."

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
