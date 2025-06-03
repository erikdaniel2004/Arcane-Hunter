#!/bin/sh
echo -ne '\033c\033]0;Arcane Hunter\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/ArcaneHunter_Linux.exe.x86_64" "$@"
