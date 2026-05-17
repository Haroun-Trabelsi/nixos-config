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
          name = "vscord";
          publisher = "LeonardSSH";
          version = "5.3.9";
          sha256 = "0b26fm87pakxjhrsh2jm4cb7l2w1k5ffyfsfvxwqh8s426bli68d";
        }
      ];
  };
}
