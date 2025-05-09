#!/bin/sh
#
# /etc/profile.d/check-nvidia.sh
# Detect NVIDIA GPU and prompt to install nvidia-driver-kainatos if missing.

# Only proceed in a graphical session (so we have a DISPLAY and kdialog)
if [ -n "$DISPLAY" ] && command -v kdialog >/dev/null 2>&1; then

  # 1. Detect NVIDIA GPU
  if lspci | grep -i nvidia >/dev/null 2>&1; then

    # 2. Check if the custom driver package is installed
    if ! dpkg -l nvidia-driver-kainatos 2>/dev/null | grep -q '^ii'; then

      # 3. Prompt the user
      if kdialog --title "NVIDIA Driver Missing" \
                 --yesno "It appears you have an NVIDIA GPU, but the proprietary driver 'nvidia-driver-kainatos' is not installed.\n\nWould you like to download and install it now?"; then

        # 4. Launch Konsole to show installation logs
        konsole --noclose -e bash -c "
          echo '🪛Starting installation of nvidia-driver-kainatos...';
          echo 'You may be prompted for your password.';
          pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY bash -c '
            apt update && apt install -y nvidia-driver-kainatos
          ';
          echo;
          echo 'Installation complete. Press Enter to close this window.';
          read
        " &

      fi

    fi
  fi
fi
