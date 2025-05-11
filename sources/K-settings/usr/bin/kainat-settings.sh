#!/bin/sh
echo -ne '\033c\033]0;Simple-settings\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/kainat-settings.x86_64" "$@"
