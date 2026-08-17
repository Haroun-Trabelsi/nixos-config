#!/usr/bin/env bash
# grimblast is Hyprland-only; grimshot is its sway counterpart.
# Note: no --freeze equivalent (that was a Hyprland feature). Add `wayfreeze`
# if freezing the screen during selection turns out to matter.
dir="$HOME/Pictures/Screenshots"
time=$(date +'%Y_%m_%d_at_%Hh%Mm%Ss')
file="${dir}/Screenshot_${time}.png"

mkdir -p "$dir"

case "$1" in
    --copy)   grimshot --notify copy area ;;
    --save)   grimshot --notify save area "$file" ;;
    --swappy) grimshot save area "$file" && swappy -f "$file" ;;
    *)        grimshot --notify copy area ;;
esac
