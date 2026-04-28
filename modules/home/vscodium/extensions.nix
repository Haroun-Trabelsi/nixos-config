{ pkgs, ... }:
{
  programs.vscode.profiles.default = {
    extensions =
      (with pkgs.vscode-extensions; [
        ## Languages
        jnoortheen.nix-ide
        arrterian.nix-env-selector
        # ms-python.python
        llvm-vs-code-extensions.vscode-clangd
        ziglang.vscode-zig
        tamasfe.even-better-toml
        golang.go
      ])
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "discord-vscode";
          publisher = "icrawl";
          version = "5.9.2";
          sha256 = "1ndvl8k7r9jqal4mhhivnnk2li4sq0pm7fddrs6ilh19l30l0xp3";
        }
      ];
  };
}
