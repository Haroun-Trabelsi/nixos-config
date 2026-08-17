{ ... }:
{
  imports = [
    # inputs.caelestia-shell.homeManagerModules.default
    ./bat.nix # better cat command
    ./btop.nix # resouces monitor
    ./discord.nix # discord
    ./fastfetch/fastfetch.nix # fetch tool
    ./fzf.nix # fuzzy finder
    ./kitty.nix # terminal
    ./git.nix # version control
    ./gnome.nix # gnome apps
    ./gtk.nix # gtk theme
    ./sway # window manager
    ./theme.nix # frozen palette, single source of truth for colours
    ./imv.nix # image viewer desktop entry
    ./lazygit.nix
    ./linear-plan.nix # claude-plan:// handler for planning Linear issues
    # ./nemo.nix # file manager (replaced by dolphin)
    ./dolphin.nix # file manager
    ./nvim.nix # neovim editor
    ./obsidian.nix
    ./thorium.nix
    ./p10k/p10k.nix
    ./slack.nix
    ./packages # other packages
    ./pomo/pomo.nix # TUI Pomodoro timer
    # ./rofi/rofi.nix # launcher (replaced by noctalia launcher)
    ./../../scripts/scripts.nix # personal scripts
    ./ssh.nix # ssh config
    ./spicetify.nix # spotify client

    ./swayosd.nix # brightness / volume wiget
    ./vscodium # vscode fork
    # ./waypaper.nix # replaced by noctalia wallpaper
    ./sops-env.nix # expose sops secrets as systemd session env vars
    ./xdg-mimes.nix # xdg config
    ./zsh # shell
  ];

}
