#!/usr/bin/env bash

command="$@"

command_window_address=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]?,.floating_nodes[]?) | select(.focused==true) | .id')

focus() {
    swaymsg "[con_id=$command_window_address] focus" > /dev/null
}

start_time=$(date +%s)

$command
exit_status=$?

end_time=$(date +%s)
duration=$(($end_time - $start_time))
duration_formatted="$((duration / 60))m $(printf "%02d" $((duration % 60)))s"

active_window_address=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]?,.floating_nodes[]?) | select(.focused==true) | .id')

if [ "$active_window_address" != "$command_window_address" ]; then
    if [ $exit_status -ne 0 ]; then
        action=$(
            notify-send -u critical \
                --action="focus=focus" \
                "NixOS Flake" \
                "\'$command\' failed after $duration_formatted" 2> /dev/null
        )

        [ "$action" = "focus" ] && focus
    else
        notify-send -u normal \
            "NixOS Flake" \
            "\'$command\' succeeded after $duration_formatted" 2> /dev/null
    fi
fi

if [ $exit_status -ne 0 ]; then
    exit 1
fi
