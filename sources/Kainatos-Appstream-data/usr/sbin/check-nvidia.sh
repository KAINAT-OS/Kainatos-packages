#!/bin/bash

# NVIDIA Driver Installer for KainatOS
# Supports open/proprietary drivers, license prompt, sudo via zenity, and error reporting.

set -e

LICENSE_URL="https://www.nvidia.com/en-us/drivers/nvidia-license/linux"
LICENSE_FILE="/tmp/NVIDIA_DRIVER_LICENSE.txt"
TMPDIR=$(mktemp -d)
LOGFILE="/tmp/nvidia-installer.log"

# === Zenity Helper Functions ===
prompt_error() {
    zenity --error --title="❌ Error" --text="$1\n\nCheck log: $LOGFILE"
    exit 1
}

prompt_success() {
    if ! zenity --info --title="✅ Done" --text="NVIDIA Driver installed successfully!" --checkbox="reboot now"; then
        echo "$PASSWORD" | sudo -S reboot
    exit 0
}

# === Detect GPU ===
if ! lspci | grep -i nvidia >/dev/null 2>&1; then
    exit 0  # No NVIDIA GPU detected
fi

# === Check if already installed ===
if command -v nvidia-smi >/dev/null 2>&1; then
    exit 0  # Already installed
fi

# === Ask user if they want to install ===
if ! zenity --question --title "NVIDIA Driver Missing" \
    --text "You have an NVIDIA GPU but the driver is missing.\n\nInstall it now?"; then
    exit 0
fi

# === Check Internet Connection ===
if ! ping -c1 -W2 1.1.1.1 >/dev/null 2>&1; then
    zenity --error --title="No Internet Connection" \
        --text="⚠️ Internet is required to download the NVIDIA driver.\n\nPlease connect to the internet and try again."
    exit 1
fi

# === Choose Open Source or Proprietary Driver ===
if zenity --question --title "Driver Choice" \
    --text="Install the **Open Source** NVIDIA driver?\n\nIf you click No, the **Proprietary** driver will be installed with NVIDIA's license."; then
    DRIVER_TYPE="open"
else
    DRIVER_TYPE="proprietary"
fi

# === Download License and Show ===
if [ "$DRIVER_TYPE" = "proprietary" ]; then
    curl -fsSL "$LICENSE_URL" -o "$LICENSE_FILE" || prompt_error "Failed to download NVIDIA License."
    if ! zenity --text-info --title="NVIDIA License Agreement" --filename="$LICENSE_FILE" --checkbox="I Agree to the License"; then
        prompt_error "You must accept the license to continue."
    fi
fi

# === Ask for Admin Password ===
zenity --password --title="Admin Privileges Required" > /tmp/nvidia-password.txt || prompt_error "No password entered."
PASSWORD=$(< /tmp/nvidia-password.txt)
rm /tmp/nvidia-password.txt

# === Installation Process ===
(
echo "# Installing kernel headers..."
echo "$PASSWORD" | sudo -S apt install -y linux-headers-$(uname -r) >> "$LOGFILE" 2>&1 || exit 1

echo "# Installing CUDA keyring..."
cd "$TMPDIR"
ARCH=$(dpkg --print-architecture)
BASE="debian12"
wget -q "https://developer.download.nvidia.com/compute/cuda/repos/${BASE}/${ARCH}/cuda-keyring_1.1-1_all.deb" || exit 1
echo "$PASSWORD" | sudo -S dpkg -i cuda-keyring_1.1-1_all.deb >> "$LOGFILE" 2>&1 || exit 1

echo "# Updating package list..."
echo "$PASSWORD" | sudo -S apt update >> "$LOGFILE" 2>&1 || exit 1

if [ "$DRIVER_TYPE" = "open" ]; then
    echo "# Installing Open Source NVIDIA driver..."
    echo "$PASSWORD" | sudo -S apt install -y nvidia-open >> "$LOGFILE" 2>&1 || exit 1
else
    echo "# Installing Proprietary NVIDIA driver..."
    echo "$PASSWORD" | sudo -S apt install -y cuda-drivers >> "$LOGFILE" 2>&1 || exit 1
fi
) | zenity --progress --title="Installing NVIDIA Driver..." \
           --pulsate --auto-close --width=400 --height=100 \
           --text="⏳ Please wait while the driver is being installed..." || prompt_error "Installation failed or was canceled."

# === Success Message ===
prompt_success
