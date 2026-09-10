{ inputs, ... }:
{
  # gpakosz/.tmux — "Oh my tmux!". Upstream ships two files with different
  # lifecycles:
  #
  #   .tmux.conf        upstream's config. Never meant to be edited, so it is a
  #                     read-only symlink into the Nix store and updates with the
  #                     flake input.
  #
  #   .tmux.conf.local  upstream's design is that YOU edit this one. It used to be
  #                     SEEDED once by an activation script and then left alone,
  #                     which meant its contents lived outside git: a fresh install
  #                     got upstream's defaults, not yours, and any tweak was
  #                     one disk failure from gone.
  #
  #                     It is now VENDORED into this repo (./tmux/tmux.conf.local)
  #                     and installed declaratively. The vendored copy was
  #                     byte-identical to upstream's template when it was adopted,
  #                     so nothing was lost in the move.
  #
  # Trade-off, stated plainly: ~/.tmux.conf.local is now a read-only symlink into
  # the store, so you can no longer tweak it live and see the result on the next
  # `tmux source-file`. Edit ./tmux/tmux.conf.local in this repo and rebuild
  # instead — which is the point, and is the same call already made for
  # modules/home/theme.nix.
  #
  # To go back to live editing, replace the `source` line below with the old
  # `home.activation.seedTmuxLocal` block (see git history for this file).
  #
  # tmux itself is installed from modules/home/packages/dev.nix.
  home.file.".tmux.conf".source = "${inputs.oh-my-tmux}/.tmux.conf";
  home.file.".tmux.conf.local".source = ./tmux/tmux.conf.local;
}
