#!/usr/bin/env bash
# Directory to store .desktop entries
desktop_dir="/computer"

# Clean old entries
rm -f "${desktop_dir}"/*

# Function to build a usage bar string
build_bar() {
  local used_pct=$1
  local length=10
  local used_count=$(( used_pct * length / 100 ))
  local free_count=$(( length - used_count ))
  local bar=""
  for ((i=0; i<used_count; i++)); do bar+="█"; done
  for ((i=0; i<free_count; i++)); do bar+="░"; done
  printf "%s" "$bar"
}

# Loop through df lines, parsing mount-point safely
df -h --output=target,size,used,avail,pcent,fstype | tail -n +2 | \
while IFS= read -r line; do
  [ -z "$line" ] && continue

  # Peel off fields from end: fstype, use%, avail, used, size
  fs_type=${line##* }
  rest=${line% *}
  fs_useperc=${rest##* }
  rest=${rest% *}
  fs_avail=${rest##* }
  rest=${rest% *}
  fs_used=${rest##* }
  rest=${rest% *}
  fs_size=${rest##* }
  mount_point=$rest

  # Exclude system partitions
  if [[ "$mount_point" =~ ^/(boot|proc|sys|dev|run|tmp|var/lib/docker|snap)($|/) ]]; then
    continue
  fi

  # Device and label
  device=$(findmnt -n -o SOURCE --target "${mount_point}")
  drive_label=$(lsblk -no LABEL "${device}")
  drive_label=${drive_label:-$(basename "${mount_point}")}

  # Strip '%' and compute bar
  used_pct=${fs_useperc%%%}
  bar=$(build_bar "$used_pct")

  # Choose icon and warning based on usage
  if (( used_pct >= 100 )); then
    ICON="dialog-error"
    warning="[ ! DISK IS FULL ]"
  elif (( used_pct >= 90 )); then
    ICON="dialog-warning"
    warning="[ ! LOW SPACE ]"
  else
    ICON="drive-harddisk"
    warning=""
  fi

  # Filenames & labels
  free_space=${fs_avail}
  total_space=${fs_size}
  filename="${drive_label}    [ ${free_space} free | ${total_space} ] ⎥${bar}⎢   ${warning}"
  desktop_file="${desktop_dir}/${filename}"

  # Write .desktop
  cat > "${desktop_file}" <<ENTRY
[Desktop Entry]
Type=Link
Name=${drive_label} [${free_space}|${total_space}] [${bar}] ${fs_useperc}
Icon=${ICON}
URL=file://${mount_point}
Terminal=false
ENTRY
  chmod +x "${desktop_file}"
done

echo "Mounted-drive entries created in ${desktop_dir}."

# —— Now $HOME —— #
home_label="Home"
# Reuse peel-off trick on a single-record df
line=$(df -h --output=target,size,used,avail,pcent | tail -n 1)
# peel off last four fields (no fstype here)
home_useperc=${line##* }
rest=${line% *}
home_avail=${rest##* }
rest=${rest% *}
home_used=${rest##* }
rest=${rest% *}
home_total=${rest##* }
# mount-point is in line but we know it’s $HOME
used_pct=${home_useperc%%%}
bar=$(build_bar "$used_pct")

if (( used_pct >= 100 )); then
  ICON="dialog-error"
  warning="[ ! DISK IS FULL ]"
elif (( used_pct >= 90 )); then
  ICON="dialog-warning"
  warning="[ ! LOW SPACE ]"
else
  ICON="user-home"
  warning=""
fi

home_filename="${home_label}    [ ${home_avail} free | ${home_total} ] ⎥${bar}⎢   ${warning}"
home_desktop_file="${desktop_dir}/${home_filename}"

cat > "${home_desktop_file}" <<ENTRY
[Desktop Entry]
Type=Link
Name=${home_label} [${home_avail}|${home_total}] [${bar}] ${home_useperc}
Icon=${ICON}
URL=file://${HOME}
Terminal=false
ENTRY
chmod +x "${home_desktop_file}"

echo "Home entry created in ${desktop_dir}."

# —— Unmounted block devices —— #
mapfile -t unmounted_devices < <(
  lsblk -pnlo NAME,TYPE,MOUNTPOINT | awk '$2=="part" && $3=="" {print $1}'
)

for device in "${unmounted_devices[@]}"; do
  dev_label=$(lsblk -no LABEL "$device")
  dev_label=${dev_label:-$(basename "$device")}
  total_size=$(lsblk -dnlo SIZE "$device")
  free_space="N/A"
  fs_useperc="0%"
  bar=$(build_bar 0)
  ICON="disk-quota-critical"
  warning="⚠️ unmounted — click to mount"

  umount_filename="${dev_label} [ ${free_space} | ${total_size} ] ⎥${bar}⎢   ${warning}"
  umount_desktop_file="${desktop_dir}/${umount_filename}"

  cat > "${umount_desktop_file}" <<ENTRY
[Desktop Entry]
Type=Application
Name=${dev_label} [${free_space}|${total_size}] [${bar}] ${fs_useperc}
Icon=${ICON}
Exec=udisksctl mount -b ${device} && "${0}"
Terminal=false
ENTRY
  chmod +x "${umount_desktop_file}"
done

echo "Unmounted-device entries created in ${desktop_dir}."
