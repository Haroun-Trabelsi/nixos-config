#!/usr/bin/env bash
# qywall — animated video wallpaper switcher using mpvpaper + qylock themes
#
# Usage:
#   qywall              — open rofi picker
#   qywall set <theme>  — set wallpaper to a specific theme
#   qywall list         — list available video themes
#   qywall restore      — restore last-saved wallpaper (for exec-once)

CONFIG="$HOME/.config/qylock/wallpaper"
# QYLOCK_THEMES is set at build time by nix (see exec-once.nix)
THEMES_DIR="${QYLOCK_THEMES:-}"

list_themes() {
    for dir in "$THEMES_DIR"/*/; do
        [ -f "$dir/bg.mp4" ] && basename "$dir"
    done
}

set_wallpaper() {
    local theme="$1"
    local video="$THEMES_DIR/$theme/bg.mp4"

    if [ ! -f "$video" ]; then
        notify-send "qywall" "No video for theme: $theme" 2>/dev/null
        exit 1
    fi

    # Kill any running mpvpaper
    pkill -x mpvpaper 2>/dev/null
    sleep 0.3

    # Start mpvpaper on every active monitor
    hyprctl monitors -j | jq -r '.[].name' | while read -r output; do
        mpvpaper -f -o "no-audio loop-file=inf hwdec=auto" "$output" "$video" &
    done

    # Persist choice
    mkdir -p "$(dirname "$CONFIG")"
    echo "$theme" > "$CONFIG"
}

case "${1:-menu}" in
    list)
        list_themes
        ;;
    set)
        set_wallpaper "${2:?Usage: qywall set <theme>}"
        ;;
    restore)
        if [ -f "$CONFIG" ]; then
            set_wallpaper "$(cat "$CONFIG")"
        else
            set_wallpaper "pixel-hollowknight"
        fi
        ;;
    menu|"")
        selected=$(list_themes | rofi -dmenu -i -p "  Wallpaper")
        [ -n "$selected" ] && set_wallpaper "$selected"
        ;;
esac
