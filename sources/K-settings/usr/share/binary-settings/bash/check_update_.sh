#!/bin/bash
#K-SETTINGS
# source the online version
source <(curl -s https://raw.githubusercontent.com/KAINAT-OS/K-SETTINGS/refs/heads/main/version.sh)
# source the offline version
source /usr/share/binary-updater/K-SETTINGS/version.sh
if [ "$offline_version" != "$VERSION" ]; then
    export K_update_avil="$K_update_avil:K-SETTINGS"
fi



#checking
if [ -z "$K_update_avil" ] && [ "$K_update_avil" = "" ]; then
    :
else
    kdialog --title "Update Notification" --yesno "Updates are available do you want to update now?"
    if [ $? = 0 ]; then
        export PASSWORD=$(kdialog --password "Enter the password")
        bash -c "$(curl -sL https://raw.githubusercontent.com/KAINAT-OS/K-SETTINGS/refs/heads/main/install.sh)"
    fi
fi
