{
  lib,
  inputs,
  ...
}:
{
  # gpakosz/.tmux — "Oh my tmux!". Upstream ships two files with different
  # lifecycles, and they are handled differently on purpose:
  #
  #   .tmux.conf        upstream's config. Never meant to be edited, so it is a
  #                     read-only symlink into the Nix store and updates with the
  #                     flake input.
  #
  #   .tmux.conf.local  YOUR customisations. Upstream's whole design is that you
  #                     edit this file. Managing it as a store symlink would make
  #                     it read-only and break that workflow — the same trap that
  #                     bit ~/.ssh/config with Zed. So it is SEEDED once from
  #                     upstream's annotated template and then left alone.
  #
  # Trade-off, stated plainly: edits to ~/.tmux.conf.local are yours and live
  # outside git, so a fresh install gets upstream's defaults rather than your
  # tweaks. If you want them reproducible, move the file's content into this
  # module as `home.file.".tmux.conf.local".text` and drop the seeding block.
  #
  # tmux itself is installed from modules/home/packages/dev.nix.
  home.file.".tmux.conf".source = "${inputs.oh-my-tmux}/.tmux.conf";

  home.activation.seedTmuxLocal = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.tmux.conf.local" ]; then
      run install -m644 ${inputs.oh-my-tmux}/.tmux.conf.local "$HOME/.tmux.conf.local"
      run echo "seeded ~/.tmux.conf.local from oh-my-tmux — edit it freely, it will not be overwritten"
    fi
  '';
}
