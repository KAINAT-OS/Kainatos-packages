#!/bin/sh
echo -ne '\033c\033]0;K-settings\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/K-settings.x86_64" "$@"
