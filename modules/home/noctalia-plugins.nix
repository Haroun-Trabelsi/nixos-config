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
# OFFICIAL vs COMMUNITY: these come from noctalia-dev/official-plugins, which is
# a SEPARATE repo from noctalia-dev/noctalia-plugins. The community registry has
# no bitwarden plugin at all, which is easy to mistake for "it does not exist".
#
# `recursive = true` symlinks each FILE rather than the directory, leaving the
# plugin directory itself writable — plugins keep their own state beside their
# code, and a read-only directory symlink would break that.
let
  isDesktop = osConfig.machine.profile == "desktop";

  plugins = [
    "bongocat" # widget noctalia/bongocat:cat — slaps when you type
    "screen_recorder" # widget noctalia/screen_recorder:recorder
    "bitwarden" # NO bar widget: launcher-only, "/bw" prefix, plus panels
  ];
in
{
  xdg.dataFile = lib.mkIf isDesktop (
    lib.listToAttrs (
      map (p: {
        name = "noctalia/plugins/${p}";
        value = {
          source = "${inputs.noctalia-official-plugins}/${p}";
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
      bitwarden-cli # bitwarden drives `bw serve`; the plugin needs `bw` on PATH
      evtest # bongocat reads key events through this for typing reactivity
    ]
  );
}
