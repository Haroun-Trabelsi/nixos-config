{
  osConfig,
  inputs,
  lib,
  pkgs,
  ...
}:
# Noctalia 5.x plugins, placed from a pinned input rather than fetched.
#
# WHERE: 5.x loads local plugins from dataDir()/plugins, i.e.
# ~/.local/share/noctalia/plugins/<dir>/ with a plugin.toml inside
# (src/scripting/plugin_source_paths.cpp -> localSourceRoot, and
# src/util/file_utils.h -> dataDir). Note that is the DATA dir, not the config
# dir the 4.x QML plugins used.
#
# WHY NOT LET IT FETCH: noctalia can clone a plugin source itself, which would
# make the bar's widgets whatever was on main that day, recorded nowhere.
# inputs.noctalia-official-plugins pins the repo into flake.lock instead.
#
# OFFICIAL vs COMMUNITY: 5.x plugins live in TWO repos —
# noctalia-dev/official-plugins and noctalia-dev/community-plugins — and neither
# is the 4.x noctalia-dev/noctalia-plugins. Searching only one of the three is
# how a plugin comes to look like it "does not exist".
#
# `recursive = true` symlinks each FILE rather than the directory, leaving the
# plugin directory itself writable — plugins keep their own state beside their
# code, and a read-only directory symlink would break that.
#
# PLACING A PLUGIN HERE DOES NOT TURN IT ON. Being in the data dir makes a
# plugin AVAILABLE; a separate enabled list decides whether it loads, and it
# lives in runtime state that config.toml cannot express — there is no
# [plugins] section in noctalia's example.toml:
#
#     ~/.local/state/noctalia/settings.toml
#     [plugins]
#     enabled = [ "noctalia/bongocat", ... ]
#
# So every plugin added here needs a ONE-TIME, per-machine:
#
#     noctalia msg plugins enable <author/plugin>     # PLUGIN id, no :entry
#     noctalia msg plugins list                       # verify: enabled/disabled
#
# This is why a plugin can be linked, correctly configured, present in the
# bar's widget list AND still render nothing — which is exactly how nix-monitor
# shipped, silently disabled from the commit that added it until 2026-09-15.
# `noctalia msg plugins list` is the check that would have caught it; a green
# build never will.
#
# Note also that noctalia loads config.toml at STARTUP and nothing restarts it
# on a home-manager switch (it is a Hyprland exec-once, not a user unit), so a
# switch alone changes nothing on the running shell. Follow one with:
#
#     noctalia msg config-reload
let
  isDesktop = osConfig.machine.profile == "desktop";

  # dir = the directory inside the source repo; src = which pinned repo it is in.
  plugins = [
    {
      dir = "bongocat";
      src = inputs.noctalia-official-plugins;
    } # widget noctalia/bongocat:cat — slaps when you type
    {
      dir = "screen_recorder";
      src = inputs.noctalia-official-plugins;
    } # widget noctalia/screen_recorder:recorder
    {
      dir = "nix-monitor";
      src = inputs.noctalia-community-plugins;
    } # widget avivbintangaringga/nix-monitor:nix-monitor
    {
      dir = "obsidian";
      src = inputs.noctalia-community-plugins;
    } # widget davemhammer/obsidian:status, panel :manager, "/ob" launcher
  ];
in
{
  xdg.dataFile = lib.mkIf isDesktop (
    lib.listToAttrs (
      map (p: {
        name = "noctalia/plugins/${p.dir}";
        value = {
          source = "${p.src}/${p.dir}";
          recursive = true;
        };
      }) plugins
    )
  );

  # Each plugin's runtime dependency. Without these the widgets load and then
  # fail at the point of use, which is the least helpful way to find out.
  home.packages = lib.mkIf isDesktop (
    with pkgs;
    [
      gpu-screen-recorder # screen_recorder does the actual capture with this
      evtest # bongocat reads key events through this for typing reactivity
      # nix-monitor shells out to nix, nixos-version, nixos-rebuild, nix-store,
      # git and coreutils. All of those are already in this system's closure —
      # checked, not assumed — so it needs nothing added here.
      #
      # obsidian declares obsidian, git, xdg-open, find, sort, head, realpath.
      # obsidian comes from modules/home/obsidian.nix, xdg-open from xdg-utils
      # in the user profile, the rest from coreutils/findutils — all already
      # on PATH, likewise checked, so nothing to add.
    ]
  );
}
