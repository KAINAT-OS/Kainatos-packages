#!/bin/sh
echo -ne '\033c\033]0;package-installer\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/deb-installer-kainatos.x86_64" "$@"
