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
      dir = "bitwarden";
      src = inputs.noctalia-official-plugins;
    } # NO bar widget: launcher-only, "/bw" prefix, plus panels
    {
      dir = "nix-monitor";
      src = inputs.noctalia-community-plugins;
    } # widget avivbintangaringga/nix-monitor:nix-monitor
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
      bitwarden-cli # bitwarden drives `bw serve`; the plugin needs `bw` on PATH
      evtest # bongocat reads key events through this for typing reactivity
      # nix-monitor shells out to nix, nixos-version, nixos-rebuild, nix-store,
      # git and coreutils. All of those are already in this system's closure —
      # checked, not assumed — so it needs nothing added here.
    ]
  );
}
