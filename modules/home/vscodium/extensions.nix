{ pkgs, ... }:
{
  programs.vscodium.profiles.default = {
    extensions = with pkgs.vscode-extensions; [
      ## Theme
      # Icon theme only. The colour theme is Abyss, which ships inside
      # VSCodium and needs nothing declared here. catppuccin-vsc (the colour
      # theme half) was dropped when Abyss replaced it rather than left
      # installed-but-unused.
      #
      # This MUST stay declared: userSettings only names an icon theme, it
      # cannot install one. settings.nix has asked for "catppuccin-macchiato"
      # for a long time while shipping no extension to provide it.
      catppuccin.catppuccin-vsc-icons # icon theme -> "catppuccin-macchiato"

      ## Languages
      jnoortheen.nix-ide
      arrterian.nix-env-selector
      # ms-python.python
      llvm-vs-code-extensions.vscode-clangd
      ziglang.vscode-zig
      tamasfe.even-better-toml
      golang.go
    ];
  };
}
