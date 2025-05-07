#!/bin/sh
echo -ne '\033c\033]0;kos_splash\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/splash.x86_64" "$@"
