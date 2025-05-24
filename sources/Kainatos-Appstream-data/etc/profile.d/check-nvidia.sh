#!/bin/sh
#
# /etc/profile.d/check-nvidia.sh
# Detect NVIDIA GPU and prompt to open Discover app to install nvidia-driver-kainatos if missing.

# Only proceed in a graphical session (so we have a DISPLAY and kdialog)
if [ -n "$DISPLAY" ] && command -v kdialog >/dev/null 2>&1; then

  # 1. Detect NVIDIA GPU
  if lspci | grep -i nvidia >/dev/null 2>&1; then

    # 2. Check if the custom driver package is installed
    if ! dpkg -l nvidia-driver-kainatos 2>/dev/null | grep -q '^ii'; then

      # 3. Prompt the user
      if kdialog --title "NVIDIA Driver Missing" \
                 --yesno "It appears you have an NVIDIA GPU, but the proprietary driver 'nvidia-driver-kainatos' is not installed.\n\nWould you like to open Discover to install it now?"; then

        # 4. Open Discover with the appstream URL
        discover "appstream://org.kainatos.nvidia.driver.kainatos" &

      fi

    fi
  fi
fi
