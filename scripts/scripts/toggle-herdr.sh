#!/usr/bin/env bash
# The herdr session that lives on the Coder workspace, in its own kitty.
#
# --remote attaches to the herdr server running on the workspace rather than
# starting a local one, so the panes (and the claude sessions in them) keep
# running when this window closes or the machine sleeps. linear-investigate
# drives the same server through `herdr --machine haroun`.
#
# Its own --class so toggle-app can tell it apart from every other kitty.
exec toggle-app herdr-coder kitty --class herdr-coder herdr --remote coder.haroun
