<h1 align="center">
   <img src="./.github/assets/logo/nixos-logo.png" width="100px" />
   <br>
      One SSD, Two Machines
   <br>
      <img src="./.github/assets/pallet/pallet-0.png" width="600px" /> <br>

   <div align="center">
      <p></p>
      <div align="center">
         <a href="https://github.com/Haroun-Trabelsi/nixos-config/stargazers">
            <img src="https://img.shields.io/github/stars/Haroun-Trabelsi/nixos-config?color=FABD2F&labelColor=282828&style=for-the-badge&logo=starship&logoColor=FABD2F">
         </a>
         <a href="https://github.com/Haroun-Trabelsi/nixos-config/">
            <img src="https://img.shields.io/github/repo-size/Haroun-Trabelsi/nixos-config?color=B16286&labelColor=282828&style=for-the-badge&logo=github&logoColor=B16286">
         </a>
         <a href="https://nixos.org">
            <img src="https://img.shields.io/badge/NixOS-unstable-blue.svg?style=for-the-badge&labelColor=282828&logo=NixOS&logoColor=458588&color=458588">
         </a>
         <a href="https://github.com/Haroun-Trabelsi/nixos-config/blob/main/LICENSE">
            <img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&colorA=282828&colorB=98971A&logo=unlicense&logoColor=98971A&"/>
         </a>
      </div>
      <br>
   </div>
</h1>

<p align="center">
   A single NixOS configuration on one portable SSD that boots
   <b>two different computers</b> — an Intel ASUS Vivobook running sway, and an
   AMD tower with an RTX 5060 Ti running Hyprland. You pick the machine from the
   boot menu, not by rebuilding. Secure Boot via Lanzaboote, secrets via
   sops-nix.
</p>

### 🖼️ Gallery

<p align="center">
   <img src="./.github/assets/screenshots/1.png" style="margin-bottom: 15px;"/> <br>
   <img src="./.github/assets/screenshots/2.png" style="margin-bottom: 15px;"/> <br>
   <img src="./.github/assets/screenshots/3.png" style="margin-bottom: 15px;"/> <br>
   <img src="./.github/assets/screenshots/4.png" style="margin-bottom: 15px;"/> <br>
   Screenshots last updated <b>2025-12-25</b> — they show the Hyprland desktop
   with Waybar and Hyprlock, both of which have since been replaced
   (i3status-rust/noctalia and swaylock). The laptop's sway session is not
   pictured.
</p>

<details>
<summary>
   Swaylock (EXPAND)
</summary>
   <img src="./.github/assets/screenshots/swaylock.png" style="margin-bottom: 15px;" /> <br>
</details>
<details>
<summary>
   Power menu (EXPAND)
</summary>
   <img src="./.github/assets/screenshots/power_menu.png" style="margin-bottom: 15px;" /> <br>
</details>
<details>
<summary>
   Launcher (EXPAND)
</summary>
   <img src="./.github/assets/screenshots/launcher.png" style="margin-bottom: 15px;" /> <br>
</details>
<details>
<summary>
   Wallpapers picker (EXPAND)
</summary>
   <img src="./.github/assets/screenshots/wallpaper_picker.png" style="margin-bottom: 15px;" /> <br>
</details>
<details>
<summary>
   Notification (EXPAND)
</summary>
   <img src="./.github/assets/screenshots/notification.png" style="margin-bottom: 15px;" /> <br>
</details>
<details>
<summary>
   Notification center (EXPAND)
</summary>
   <img src="./.github/assets/screenshots/notification_center.png" style="margin-bottom: 15px;" /> <br>
</details>

# 🗃️ Overview

> [!IMPORTANT]
> This is my **personal** NixOS configuration, shared for reference.
>
> - It changes constantly — expect breaking changes.
> - Features may be partially implemented or broken.
> - No guarantees of stability.
>
> Read it, understand what a module does, and adapt it — do not copy it whole.

### The unusual part

Most multi-machine Nix configs give each machine its own `nixosConfiguration`.
This one cannot, and the reason drives the whole layout.

There is **one** portable SSD, **one** ESP, and therefore **one** bootloader
install. Under [Lanzaboote](https://github.com/nix-community/lanzaboote) a
rebuild that omitted the bootloader would drop an unsigned `systemd-bootx64.efi`
over the signed one, and the other machine would then fail Secure Boot and need
a firmware trip to recover.

So the **laptop is the base config**, and the **tower is a NixOS
`specialisation` inside it** — its own signed UKI and boot-menu entry per
generation, chosen at boot with no rebuild before physically moving the disk.
The base has to be the minimal machine, because the module system adds cleanly
but cannot remove: a specialisation can append kernel parameters, but it cannot
un-set `services.xserver.videoDrivers` or delete a `fileSystems` entry.

Machine-specific modules gate on `config.machine.profile` (`"laptop"` /
`"desktop"`), and home-manager modules read it as `osConfig.machine.profile`.
This replaced a `host` specialArg, which could not work: specialArgs are fixed
per `nixosConfiguration` and cannot vary per specialisation.

**Consequence worth knowing:** a specialisation is invisible to anything that
iterates `nixosConfigurations`, so the tower needs explicit attributes.
`nix flake check` and the `vm-*` packages below both exist for that reason —
`.#desktop` is only an alias for `.#portable`, and building it gives you the
*laptop*.

## 📚 Layout

One portable SSD boots two machines. There is a single system configuration:
the **laptop is the base**, and the **AMD/NVIDIA tower is a NixOS
`specialisation` inside it** with its own signed boot entry — you pick the
machine from the boot menu, not by rebuilding. The base has to be the minimal
machine because the module system adds cleanly but cannot remove.

-   [flake.nix](flake.nix) Base of the configuration
-   [hosts](hosts) Bootable configurations
    -   [portable](hosts/portable/) The one real config: shared hardware, the disko layout, and the `desktop` specialisation
    -   [iso](hosts/iso/) Installer ISO, with the install script baked in
-   [machines](machines) Per-machine modules, gated on `machine.profile`
    -   [laptop](machines/laptop/) ASUS Vivobook — TLP, Intel VA-API, audio quirk
    -   [desktop](machines/desktop/) AMD tower — NVIDIA, Steam, OpenRGB/DDC, TV audio
-   [modules](modules) Modularized NixOS configurations
    -   [core](modules/core/) Configuration shared by BOTH machines
    -   [homes](modules/home/) My [Home-Manager](https://github.com/nix-community/home-manager) configuration
-   [pkgs](pkgs) Custom packages build from source
-   [scripts](scripts) Custom shell scripts
-   [assets/wallpapers](assets/wallpapers/) The vendored wallpaper

## 🛠️ System Components & Applications

| Component | Software |
| --- | :---: |
| **Window Manager**          | [sway][sway] (laptop) / [Hyprland][Hyprland] (tower) |
| **Bar**                     | swaybar + [i3status-rust][i3status-rust] (laptop) / [noctalia][noctalia] (tower) |
| **Application Launcher**    | [fuzzel][fuzzel] (laptop) / [noctalia][noctalia] (tower) |
| **Notification Daemon**     | [mako][mako] (laptop) / [noctalia][noctalia] (tower) |
| **Terminal Emulator**       | [kitty][kitty] |
| **Shell**                   | [zsh][zsh] + [powerlevel10k][powerlevel10k] |
| **Text Editor**             | [VSCodium][VSCodium] + [Neovim][Neovim] |
| **network management tool** | [NetworkManager][NetworkManager] + [network-manager-applet][network-manager-applet] |
| **System resource monitor** | [Btop][Btop] |
| **File Manager**            | [Dolphin][Dolphin] |
| **Fonts**                   | [Maple Mono][Maple Mono] |
| **Color Scheme**            | Eldritch, frozen at build time in [`modules/home/theme.nix`](modules/home/theme.nix) |
| **GTK theme**               | [Colloid gtk theme][Colloid gtk theme] |
| **Cursor**                  | Nordzy-catppuccin-macchiato-dark |
| **Icons**                   | Tela-circle-purple-dark |
| **Lockscreen**              | [swaylock][swaylock] (both machines, via ext-session-lock-v1) |
| **Image Viewer**            | [imv][imv] |
| **Media Player**            | [mpv][mpv] |
| **Music Player**            | [mpd][mpd] + [rmpc][rmpc] (laptop) / Spotify + [spicetify][spicetify] (tower) |
| **Screenshot Software**     | [grimshot][grimshot] (sway) / [grimblast][grimblast] (Hyprland) |
| **Screen Recording**        | [wf-recorder][wf-recorder] + [OBS][OBS] |
| **Clipboard**               | [wl-clip-persist][wl-clip-persist] |
| **Color Picker**            | [hyprpicker][hyprpicker] |


## 📝 Shell aliases

Shell aliases are defined in two places. You can find git related aliases in [`git.nix`](./modules/home/git.nix), and all the others in [`zsh_alias.nix`](./modules/home/zsh/zsh_alias.nix).

Some notable ones that can help you are:

| Alias | Command | Purpose |
|-------|---------|---------|
| `nft` | `nh-notify nh os test`   | Test configuration changes without modifying the bootloader |
| `nfs` | `nh-notify nh os switch` | Rebuild and activate the new system configuration |
| `nfu` | `nix flake update --flake ~/nixos-config nixpkgs hyprland && nh-notify nh os switch` | Update `nixpkgs` and `hyprland` flake inputs only, then rebuild/activate |
| `ns`  | `nom-shell --run zsh` | Enter a nix shell |
| `nd`  | `nom develop --command zsh` | Enter a development environment from a `flake.nix` file |
| `nb`  | `nom build` | Build packages exported by a flake |
| `nc`  | `nh-notify nh clean all --keep 5` | Clean up old Nix generations, keeping only the 5 most recent |
| `nsearch` | `nh search` | Search nixpkgs for available packages |

## 🛠️ Custom Scripts

All of the scripts are in the [`./scripts/scripts/`](./scripts/scripts/) folder and are exported as packages in [`./scripts/scripts.nix`](./scripts/scripts.nix).

Shell scripts are automatically discovered and exported as standalone packages. The package name becomes the script base name without its extension (i.e., `ascii.sh` will become the `ascii` command).

**Note:** Scripts must have names that end with `.sh` and be tracked by git to be automatically detected.
 
**Since scripts are exposed as packages, you can**:
- Run them directly from the terminal (e.g., `ascii`)
- Bind them to keybindings (see [binds.nix](./modules/home/hyprland/binds.nix) for examples)
- Call them from other scripts or automation tools

**To add your own script**:
1. Add a new `.sh` file to `./scripts/scripts/`
2. Ensure it's executable (chmod +x)
3. Add it to git (git add `./scripts/scripts/<name>.sh`)
4. Rebuild your configuration (`nfs` or `nft`)
5. The script will be automatically available as a command

**Location:** [`./scripts/`](./scripts/)

```
scripts/
├── scripts/            # All shell scripts are here
│   └── <script>.sh
└── scripts.nix         # Automatic scripts packaging
```

## ⌨️ Keybinds

Keybindings are defined per compositor: [`sway/binds.nix`](./modules/home/sway/binds.nix) on the laptop and [`hyprland/binds.nix`](./modules/home/hyprland/binds.nix) on the tower. 

**Quick access:** Press `$mod F1` to view all keybinds.

Here are some of the main keybinds:

| Category | Keys | Purpose |
|---|---|---|
| **Navigation** | `$mod + 0-9`, `$mod + arrows/hjkl` | workspace & window navigation |
| **Navigation** | `$mod + Tab` | last workspace |
| **Launch** | `$mod + Return` / `$mod + T` | kitty (shared instance / new process) |
| **Launch** | `$mod + Shift + D` | fuzzel launcher (laptop; noctalia's on the tower) |
| **Launch** | `$mod + E` / `$mod + B` | dolphin / browser |
| **Launch** | `$mod + D` / `$mod + S` | Discord / music |
| **Launch** | `$mod + C` / `$mod + Shift + V` | VS Code in the browser (Coder) / zed |
| **Window** | `$mod + Q/F/Space` | close, fullscreen, toggle float |
| **Tools** | `$mod + Print` / `$mod + V` | screenshot / clipboard history |
| **Tools** | `$mod + W` | restore last notification (mako) |
| **System** | `$mod + Escape` / `$mod + Shift + Escape` | swaylock / power menu |
| **System** | `$mod + F1` | full keybind list |

# 🚀 Installation

## Getting this onto another disk

Three routes, fastest first.

### 1. From this running system — the fast path

If the machine is alive and booted, this is by far the quickest: the local
`/nix/store` already holds the whole closure, so most of the "build" is a local
copy rather than a download.

```bash
sudo ./scripts/recovery/install-to-disk.sh --dry-run /dev/sdX   # review the plan
sudo ./scripts/recovery/install-to-disk.sh /dev/sdX             # do it
```

It partitions with disko, **reads the new filesystem UUIDs and writes them into
its own copy of `hardware-shared.nix`** before installing, copies
`/var/lib/sbctl` so Lanzaboote can sign on the new disk, and drops the repo at
`~/nixos-config`. It refuses to target the disk you are running from.

`--swap` and `--data` add the optional partitions (both off by default).

> [!NOTE]
> The UUID rewrite is not a nicety. Installing the config verbatim would give the
> new disk a `hardware-shared.nix` naming the **old** disk's UUIDs — a non-boot,
> or worse, silently mounting the old disk if both are attached.

The one thing it deliberately does not copy is the age key. Put your off-machine
copy at `~/.config/sops/age/keys.txt` (mode 600) on the new root, or every secret
stays unavailable.

### 2. From the ISO — when this machine is dead

```bash
nix build .#iso        # ~1.4 GB, flake baked in at /etc/nixos-config
```

Write it to a USB stick, boot it, and run `install-nixos`. Same idea as above —
disko, then UUID rewriting, then `nixos-install` — but it fetches the closure
from the network, so it is much slower. Use it when there is no working system to
install *from*.

### 3. Not a clone

`dd` copies every used byte and duplicates every filesystem UUID. Two disks
claiming the same root UUID is exactly the ambiguity `by-uuid` mounts exist to
prevent, and you would then have to regenerate them and edit
`hardware-shared.nix` by hand — which is the step route 1 automates.

## Trying it without touching a disk

```bash
nix run .#vm-laptop     # sway, Intel VA-API, TLP, zram
nix run .#vm-desktop    # the tower specialisation
```

`nixos-rebuild build-vm --flake .#desktop` does **not** give you the desktop —
`.#desktop` is an alias for `.#portable`, whose base is the laptop. Use the
attributes above.

`vm-desktop` will not reach a graphical session: `machines/desktop` sets
`videoDrivers = [ "nvidia" ]` and a VM has no NVIDIA GPU. It is still the right
way to exercise filesystems, services and units.

## Checking both machines build

```bash
nix flake check     # laptop + desktop specialisation + ISO
```

Worth running before you trust either. The tower's toplevel is not reachable
from any `nixosConfigurations` attribute, so this is the only command that
proves the machine you may not be sitting at still builds.

## Knowing what is not reproducible

```bash
./scripts/recovery/audit-undeclared-state.sh     # mutable state this config does not declare
```

See **[secrets/RECOVERY.md](./secrets/RECOVERY.md)** for the inventory of state
that lives outside git — the age key, the Secure Boot PKI, the Tailscale node
identity — and the order to restore it in.

## Bootstrapping the things nix cannot do

Both install routes above leave three things for you. None can be automated,
and skipping the first two means the machine does not boot the way you expect.

### Secure Boot (Lanzaboote)

This config force-disables `systemd-boot` and signs with
[Lanzaboote](https://github.com/nix-community/lanzaboote). **A machine with
Secure Boot enabled will not boot the result unless keys are enrolled first.**

`install-to-disk.sh` copies the existing `/var/lib/sbctl` across, so a second
disk inherits working keys. Starting from nothing, put the firmware into **Setup
Mode** (clear factory keys), then:

```bash
sudo nix run nixpkgs#sbctl -- create-keys
sudo nix run nixpkgs#sbctl -- enroll-keys --microsoft   # Microsoft keys for OptionROMs
```

Re-enable Secure Boot afterwards; the next `nixos-rebuild switch` signs the
bootloader and kernel. Check with `sbctl status`.

Signing is a no-op where Secure Boot is off, which is why Lanzaboote lives in
the *shared* layer ([`modules/core/bootloader.nix`](modules/core/bootloader.nix))
rather than in a machine module — see the comment there.

Back the keys up, because losing them invalidates the signature on every
existing generation, and the boot menu is the rollback path:

```bash
sudo ./scripts/recovery/backup-secure-boot-keys.sh ~/somewhere-outside-the-repo
```

### The sops age key

Secrets in `secrets/secrets.yaml` are encrypted with
[sops-nix](https://github.com/Mic92/sops-nix). The private key is **not** in the
repo and not derivable from it:

```bash
mkdir -p ~/.config/sops/age
# restore your off-machine copy to ~/.config/sops/age/keys.txt, then:
chmod 600 ~/.config/sops/age/keys.txt
```

Without it `/run/secrets/*` never materialises: GitHub SSH breaks and
`modules/home/sops-env.nix` silently writes no environment file.
`modules/core/sops.nix` declares only the secrets actually present in the file,
so an absent optional secret does not break a rebuild.

`sops.age.sshKeyPaths` is deliberately **not** used: it needs an SSH host key,
and `services.openssh` is enabled on neither machine.

### Everything else

- **Git identity** — edit [`modules/home/git.nix`](modules/home/git.nix), then `nfs`.
- **claude-code** — `modules/home/zsh/zsh.nix` exports `CLAUDE_CODE_*`, but the
  binary comes from npm (nixpkgs lags): `npm i -g @anthropic-ai/claude-code`.
- **Tailscale** — `tailscale up`, or put a reusable auth key in
  `secrets/secrets.yaml` as `tailscale_auth_key` and
  `services.tailscale.authKeyFile` joins on first boot.
- **Coder** — `coder login`. The CLI itself is packaged
  ([`pkgs/coder`](pkgs/coder), pinned to the deployment's version).
- **Browser** — extensions are force-installed by policy
  ([`modules/core/browser-policies.nix`](modules/core/browser-policies.nix)), but
  their *settings* are profile state and are not reproducible.
- **Linear → Claude plan bookmarklet** —
  [`modules/home/linear-plan.nix`](modules/home/linear-plan.nix) registers the
  `claude-plan://` handler and writes the bookmarklet to
  `~/.local/share/linear-plan/bookmarklet.js`. Bookmarks are not nix-managed;
  add it once by hand. Clipboard fallback is `$mod SHIFT P`.
- **Hyprland monitors / workspaces** (tower only) —
  `modules/home/hyprland/monitors.nix` sources
  `~/.config/hypr/{monitors,workspaces}.conf`, both with `noerror`.

### Booting it

Every generation produces **two** boot entries: the base (laptop) and
`…-specialisation-desktop` (the tower). Pick the one matching the machine you are
on; moving the disk needs no rebuild. Lanzaboote signs both.

greetd logs straight into sway (laptop) or Hyprland (tower). Seeing
GRUB/systemd-boot instead of Lanzaboote means the keys were never enrolled —
boot the previous generation, redo the enrolment, then `nfs`.

### Known fragile spots

A non-exhaustive list of things that are tied to the current install and worth re-checking when you wipe:

- [`hosts/portable/disko.nix`](hosts/portable/disko.nix) — disk `by-id` is hardware-specific.
- [`hosts/portable/hardware-shared.nix`](hosts/portable/hardware-shared.nix) — all `fileSystems` / `swapDevices` UUIDs.
- [`modules/core/wayland.nix`](modules/core/wayland.nix) — `SSH_AUTH_SOCK` hardcodes UID `1000`. Fine for the single user here, latent bug if uid differs.
- `boot.kernelPackages = linuxPackages_latest` in [`modules/core/bootloader.nix`](modules/core/bootloader.nix) — a `nix flake update` can break the out-of-tree `ddcci-driver` or the NVIDIA open module, and only on the tower. `nix flake check` will catch it before you reboot.
- The Secure Boot PKI in `/var/lib/sbctl` and the age key are not in the repo, and this repository is **public** — see [secrets/RECOVERY.md](./secrets/RECOVERY.md).
- `pkiBundle = "/var/lib/sbctl"` in [`modules/core/bootloader.nix`](modules/core/bootloader.nix) — the Secure Boot keys live on the shared root, which is what lets a rebuild on the laptop still produce UKIs the tower accepts. Back them up; losing them means re-enrolling in firmware.
- The age key at `~/.config/sops/age/keys.txt` is not in the repo and not derivable. Without it a fresh install has no secrets, and `modules/home/sops-env.nix` fails silently rather than loudly.
- `boot.kernelPackages = pkgs.linuxPackages_latest` in [`modules/core/bootloader.nix`](modules/core/bootloader.nix) — a `nix flake update` can break the out-of-tree `ddcci-driver` or the NVIDIA open module, and only on the tower.

# 👥 Credits

This repository began as a fork of
**[Frost-Phoenix/nixos-config](https://github.com/Frost-Phoenix/nixos-config)**,
whose structure (`hosts` / `modules/core` / `modules/home`, the script
auto-discovery in `scripts/scripts.nix`, and this README's shape) is still
visible throughout. The two-machine specialisation layout, the power work, the
sway session and the reproducibility tooling are mine; the bones are theirs.

Other dotfiles learned from along the way:

- Nix Flakes
  - [nomadics9/NixOS-Flake](https://github.com/nomadics9/NixOS-Flake)
  - [samiulbasirfahim/Flakes](https://github.com/samiulbasirfahim/Flakes): General flake / files structure
  - [justinlime/dotfiles](https://github.com/justinlime/dotfiles): Mainly waybar (old design)
  - [skiletro/nixfiles](https://github.com/skiletro/nixfiles): Vscodium config (that prevent it to crash)
  - [fufexan/dotfiles](https://github.com/fufexan/dotfiles)
  - [tluijken/.dotfiles](https://github.com/tluijken/.dotfiles): base rofi config
  - [mrh/dotfiles](https://codeberg.org/mrh/dotfiles): base waybar config

- README
  - [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)
  - [NotAShelf/nyx](https://github.com/NotAShelf/nyx)
  - [sioodmy/dotfiles](https://github.com/sioodmy/dotfiles)
  - [Ruixi-rebirth/flakes](https://github.com/Ruixi-rebirth/flakes)

- And many others I probably forgot to mention.

# 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](./LICENSE) file for details.

<!-- # ✨ Stars History

<p align="center"><img src="https://api.star-history.com/svg?repos=frost-phoenix/nixos-config&type=Timeline&theme=dark" /></p> -->

<p align="center"><img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/footers/gray0_ctp_on_line.svg?sanitize=true" /></p>

<!-- end of page, send back to the top -->

<div align="right">
  <a href="#readme">Back to the Top</a>
</div>

<!-- Links -->

[Hyprland]: https://github.com/hyprwm/Hyprland
[sway]: https://swaywm.org/
[i3status-rust]: https://github.com/greshake/i3status-rust
[noctalia]: https://github.com/noctalia-dev/noctalia-shell
[fuzzel]: https://codeberg.org/dnkl/fuzzel
[mako]: https://github.com/emersion/mako
[kitty]: https://sw.kovidgoyal.net/kitty/
[Dolphin]: https://apps.kde.org/dolphin/
[swaylock]: https://github.com/swaywm/swaylock
[mpd]: https://www.musicpd.org/
[rmpc]: https://github.com/mierak/rmpc
[spicetify]: https://github.com/spicetify/cli
[grimshot]: https://github.com/OctopusET/sway-contrib
[powerlevel10k]: https://github.com/romkatv/powerlevel10k
[Btop]: https://github.com/aristocratos/btop
[zsh]: https://ohmyz.sh/
[mpv]: https://github.com/mpv-player/mpv
[VSCodium]:https://vscodium.com/
[Neovim]: https://github.com/neovim/neovim
[VSCodium]: https://vscodium.com/
[grimblast]: https://github.com/hyprwm/contrib
[imv]: https://sr.ht/~exec64/imv/
[Maple Mono]: https://github.com/subframe7536/maple-font
[NetworkManager]: https://wiki.gnome.org/Projects/NetworkManager
[network-manager-applet]: https://gitlab.gnome.org/GNOME/network-manager-applet/
[wl-clip-persist]: https://github.com/Linus789/wl-clip-persist
[wf-recorder]: https://github.com/ammen99/wf-recorder
[hyprpicker]: https://github.com/hyprwm/hyprpicker
[Colloid gtk theme]: https://github.com/vinceliuice/Colloid-gtk-theme
[OBS]: https://obsproject.com/
