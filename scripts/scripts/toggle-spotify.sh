#!/usr/bin/env bash
# Spotify is an Xwayland client, so it matches on class, not app_id.
exec toggle-app class Spotify spotify
