#!/usr/bin/env bash
# True battery rate, computed from energy_now deltas.
#
# Why not power_now: on this ASUS EC, power_now is a computed estimate that
# swings 3-18 W at random and reports status="Charging" while the battery is
# demonstrably draining. Measured: 25 min at "Charging" during which the pack
# fell 77% -> 70% (a real -5.77 W). energy_now is the actual charge counter, so
# differencing it over a window gives the truth.
#
# Emits i3status-rust custom-block JSON:
#   {"icon","state","text"}  state in Idle|Info|Good|Warning|Critical
set -uo pipefail

B=/sys/class/power_supply/BAT0
STATE="${XDG_RUNTIME_DIR:-/tmp}/battery-net.state"

[ -r "$B/energy_now" ] || { echo '{"text":""}'; exit 0; }

now=$(date +%s)
e=$(cat "$B/energy_now")
pct=$(cat "$B/capacity")
ac=$(cat /sys/class/power_supply/AC0/online 2>/dev/null || echo 0)

rate=""
if [ -r "$STATE" ]; then
  read -r pt pe < "$STATE" 2>/dev/null || { pt=""; pe=""; }
  if [ -n "${pt:-}" ] && [ -n "${pe:-}" ]; then
    dt=$(( now - pt ))
    # Need a window wide enough that the counter has actually moved.
    if [ "$dt" -ge 20 ]; then
      rate=$(awk -v de=$(( e - pe )) -v dt="$dt" 'BEGIN{printf "%.1f", (de/1e6)/(dt/3600)}')
      # Slide the anchor only once the window is long enough, so the reading
      # stays smooth instead of chasing noise.
      [ "$dt" -ge 120 ] && echo "$now $e" > "$STATE"
    fi
  else
    echo "$now $e" > "$STATE"
  fi
else
  echo "$now $e" > "$STATE"
fi

# Icon: plug when a supply is attached, otherwise a battery level glyph.
if [ "$ac" = "1" ]; then icon=""
elif [ "$pct" -ge 90 ]; then icon=""
elif [ "$pct" -ge 65 ]; then icon=""
elif [ "$pct" -ge 40 ]; then icon=""
elif [ "$pct" -ge 15 ]; then icon=""
else icon=""; fi

# State. The case worth surfacing loudly is "plugged in but still losing
# charge" — the exact condition power_now hides by saying "Charging".
state=Idle
neg=0
[ -n "$rate" ] && [ "${rate%%.*}" -lt 0 ] 2>/dev/null && neg=1
if [ "$pct" -le 10 ]; then state=Critical
elif [ "$ac" = "1" ] && [ "$neg" = "1" ]; then state=Warning
elif [ "$pct" -le 20 ]; then state=Warning
elif [ -n "$rate" ] && [ "$neg" = "0" ] && [ "${rate%%.*}" -gt 0 ] 2>/dev/null; then state=Good
fi

if [ -n "$rate" ]; then
  text=$(printf '%s %s%% %+.1fW' "$icon" "$pct" "$rate")
else
  text=$(printf '%s %s%% …' "$icon" "$pct")
fi

printf '{"icon":"","state":"%s","text":"%s"}\n' "$state" "$text"
