#!/usr/bin/env bash
# qywall — wallpaper switcher using mpvpaper + qylock themes
#
# Usage:
#   qywall                — open rofi picker
#   qywall set <theme>    — set wallpaper to a specific qylock theme
#   qywall file <path>    — set wallpaper to an arbitrary image or video file
#   qywall list           — list available video themes
#   qywall restore        — restore last-saved wallpaper (for exec-once)

CONFIG="$HOME/.config/qylock/wallpaper"
# QYLOCK_THEMES is set at build time by nix (see exec-once.nix)
THEMES_DIR="${QYLOCK_THEMES:-}"
DEFAULT_WALLPAPER="$HOME/Pictures/Wallpapers/twins-pad-wallhack.mp4"

list_themes() {
    for dir in "$THEMES_DIR"/*/; do
        [ -f "$dir/bg.mp4" ] && basename "$dir"
    done
}

play_file() {
    local file="$1"

    if [ ! -f "$file" ]; then
        notify-send "qywall" "No such file: $file" 2>/dev/null
        exit 1
    fi

    local mpv_opts="no-audio hwdec=auto loop-file=inf"
    case "${file,,}" in
        *.png|*.jpg|*.jpeg|*.webp|*.bmp|*.gif)
            mpv_opts="$mpv_opts image-display-duration=inf"
            ;;
    esac

    pkill -x mpvpaper 2>/dev/null
    sleep 0.3

    hyprctl monitors -j | jq -r '.[].name' | while read -r output; do
        mpvpaper -f -o "$mpv_opts" "$output" "$file" &
    done
}

set_theme() {
    local theme="$1"
    local video="$THEMES_DIR/$theme/bg.mp4"

    if [ ! -f "$video" ]; then
        notify-send "qywall" "No video for theme: $theme" 2>/dev/null
        exit 1
    fi

    play_file "$video"

    mkdir -p "$(dirname "$CONFIG")"
    echo "theme:$theme" > "$CONFIG"
}

set_file() {
    local file="$1"
    play_file "$file"

    mkdir -p "$(dirname "$CONFIG")"
    echo "file:$file" > "$CONFIG"
}

case "${1:-menu}" in
    list)
        list_themes
        ;;
    set)
        set_theme "${2:?Usage: qywall set <theme>}"
        ;;
    file)
        set_file "${2:?Usage: qywall file <path>}"
        ;;
    restore)
        if [ -f "$CONFIG" ]; then
            saved="$(cat "$CONFIG")"
            case "$saved" in
                theme:*) set_theme "${saved#theme:}" ;;
                file:*)  play_file "${saved#file:}" ;;
                *)       set_theme "$saved" ;;
            esac
        else
            set_file "$DEFAULT_WALLPAPER"
        fi
        ;;
    menu|"")
        selected=$(list_themes | rofi -dmenu -i -p "  Wallpaper")
        [ -n "$selected" ] && set_theme "$selected"
        ;;
esac
