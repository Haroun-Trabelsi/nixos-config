{ inputs, ... }:
{
  imports = [
    inputs.noctalia-shell.homeModules.default
    # inputs.caelestia-shell.homeManagerModules.default
    ./bat.nix # better cat command
    ./bitwarden.nix # password manager (desktop app)
    ./claude-notify-bridge.nix # desktop notifications for Claude Code in Coder
    ./claude-chrome-bridge.nix # claude-in-chrome TCP<->NMH bridge for Claude Code in Coder
    ./coder-port-forward.nix # workspace dev-server ports (8000-8009, 5173-5182) on localhost
    ./btop.nix # resouces monitor
    ./discord.nix # discord
    ./discord-rpc.nix # static OS-wide Discord Rich Presence, via vesktop's arRPC
    ./fastfetch/fastfetch.nix # fetch tool
    ./fzf.nix # fuzzy finder
    ./kitty.nix # terminal
    ./git.nix # version control
    ./gnome.nix # gnome apps
    ./gtk.nix # gtk theme
    ./herdr.nix # terminal agent multiplexer: prefix+alt+c pops a coder ssh terminal
    # BOTH compositors are imported; each gates itself on
    # osConfig.machine.profile, because module `imports` cannot depend on
    # config. Disabling a compositor makes its whole settings tree inert.
    ./sway # laptop compositor
    ./hyprland # desktop compositor
    ./wayland-tools.nix # grim/slurp/cliphist/... shared by both compositors
    ./noctalia.nix # desktop shell
    ./noctalia-plugins.nix # bongocat / screen recorder / nix-monitor / obsidian, pinned
    ./lock.nix # swaylock + swayidle, shared by both compositors
    ./tmux.nix # gpakosz/.tmux ("Oh my tmux!")
    ./theme.nix # frozen palette, single source of truth for colours
    ./imv.nix # image viewer desktop entry
    ./lazygit.nix
    ./linear-plan.nix # claude-plan:// handler for planning Linear issues
    # ./nemo.nix # file manager (replaced by dolphin)
    ./dolphin.nix # file manager
    ./nvim.nix # neovim editor
    ./obsidian.nix
    ./edge.nix # Microsoft Edge (was chromium.nix; before that, Thorium)
    ./p10k/p10k.nix
    ./packages # other packages
    ./pomo/pomo.nix # TUI Pomodoro timer
    # ./rofi/rofi.nix # launcher (replaced by noctalia launcher)
    ./../../scripts/scripts.nix # personal scripts
    ./ssh.nix # ssh config
    ./music.nix # mpd + rmpc (laptop)
    ./spicetify.nix # Spotify + spicetify (desktop)

    ./swayosd.nix # brightness / volume wiget
    ./vscodium # vscode fork
    ./wallpaper.nix # vendored wallpaper, installed to ~/Pictures/Wallpapers
    ./sops-env.nix # expose sops secrets as systemd session env vars
    ./xdg-mimes.nix # xdg config
    ./zsh # shell
  ];

}
