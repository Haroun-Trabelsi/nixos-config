{ ... }:
{
  # programs.vscodium, NOT programs.vscode with package = pkgs.vscodium.
  #
  # Both run the same editor, but they write to DIFFERENT paths, and only this
  # one matches where VSCodium actually reads:
  #
  #                     programs.vscode      programs.vscodium
  #   extensions        ~/.vscode            ~/.vscode-oss
  #   settings/keybinds ~/.config/Code/User  ~/.config/VSCodium/User
  #
  # Under the old spelling home-manager wrote the VS Code tree while VSCodium
  # read its own, so every declared extension showed up in the UI as installed
  # with its package.json "unable to resolve", and settings.json here was an
  # untracked file VSCodium maintained itself. home-manager 26.11 warns about
  # exactly this ("programs.vscode now always writes to Visual Studio Code's
  # paths").
  #
  # No `package` line: mkPackageOption already defaults it to pkgs.vscodium.
  # The binary is `codium`, not `code`.
  programs.vscodium.enable = true;
}
