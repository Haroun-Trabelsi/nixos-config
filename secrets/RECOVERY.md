# Recovery: what this repo cannot rebuild

`nix flake check` proves both machines *build*. It says nothing about whether you
could get back to a working machine from a dead disk. This file is the list of
state that lives outside git, ranked by how badly its loss hurts, and the order
to restore it in.

Everything below was inventoried on 2026-09-10 against the live system. Keep it
current — a runbook that has drifted is worse than none.

> **This repository is public** (`github.com/Haroun-Trabelsi/nixos-config`).
> Nothing secret goes in it beyond what is already age-encrypted, and the
> Secure Boot PKI deliberately does **not** go in it at all. See §2.

---

## 1. The age key — the one that can lose everything

**`~/.config/sops/age/keys.txt`** (public half `age1pv00slc…`, the recipient in
`.sops.yaml`).

Everything in `secrets/secrets.yaml` is encrypted to it: the GitHub SSH key, the
GitHub PAT, the Spotify VPN key. **And so is `secrets/bitwarden_backup.age`** —
verified, not assumed. That is a circular dependency: the backup you would reach
for after losing this key is itself locked behind this key.

Losing it means losing all of the above with no path back. It is not derivable
from anything and not stored anywhere else on this machine.

### Fix — two independent steps, do both

**a. Add a second recipient whose private half is NOT on this disk.**

```bash
# Generate an offline identity. Do this somewhere you control, NOT in the repo.
nix shell nixpkgs#age -c age-keygen -o ~/age-recovery-key.txt
chmod 600 ~/age-recovery-key.txt

# Add its PUBLIC half to .sops.yaml as a second recipient under `keys:`,
# and reference it in the creation_rules age list alongside &user, then:
nix shell nixpkgs#sops -c sops updatekeys secrets/secrets.yaml

# Re-encrypt the Bitwarden blob to BOTH recipients so it is no longer circular.
# Plaintext stays in the pipe; it never touches disk.
nix shell nixpkgs#age -c sh -c '
  age -d -i ~/.config/sops/age/keys.txt secrets/bitwarden_backup.age |
  age -r <PUBKEY_A> -r <PUBKEY_B> -o secrets/bitwarden_backup.age.new'
mv secrets/bitwarden_backup.age.new secrets/bitwarden_backup.age

# Verify BOTH identities can still read it before you commit anything.
```

**b. Move `~/age-recovery-key.txt` off this machine and delete the local copy.**
A password manager entry, a printed copy in a drawer, another machine — anything
that does not die with this SSD. `age` identities are one short line, so paper is
a legitimate medium.

`sops.age.sshKeyPaths` is **not** an option here: it needs an SSH host key, and
`services.openssh` is not enabled on either machine, so `/etc/ssh/ssh_host_*_key`
does not exist.

---

## 2. Secure Boot PKI

**`/var/lib/sbctl`** — the PK, KEK and db private keys Lanzaboote signs with.
Root-owned, mode `0400`.

Losing them is survivable but costs a firmware trip, and **invalidates the
signature on every existing generation** — which matters, because the boot menu
is the rollback path for both machines.

Deliberately **not** committed, even encrypted: this repo is public, and a single
leaked age key would then let someone sign a bootloader this firmware trusts.

```bash
sudo ./scripts/recovery/backup-secure-boot-keys.sh ~/some-dir-outside-the-repo
# then move the .tar.age off the machine
```

Restore with `sudo ./scripts/recovery/restore-secure-boot-keys.sh <blob>`, then
rebuild so Lanzaboote re-signs. Check with `sbctl status`.

If you have no backup: firmware into Setup Mode, then
`sbctl create-keys && sbctl enroll-keys --microsoft`, then rebuild.

---

## 3. Tailscale node identity

**`/var/lib/tailscale`**. Not reproducible by design — a reinstall is a *new*
node, and the old one lingers in the admin console until you delete it.

What *is* now automated: joining. Put a reusable auth key from
<https://login.tailscale.com/admin/settings/keys> into `secrets/secrets.yaml` as
`tailscale_auth_key` and `services.tailscale.authKeyFile` picks it up on first
boot with no interactive `tailscale up`.

`modules/core/sops.nix` only declares secrets whose keys are actually present in
the file, so this stays inert until you add it — it will not break a rebuild.

---

## 4. Disk UUIDs — declared twice

`hosts/portable/hardware-shared.nix` hardcodes the root / ESP / swap UUIDs, and
`hosts/portable/disko.nix` declares the same layout independently. The installer
(`hosts/iso/install.sh`) rewrites the former after disko formats, so a fresh
install is handled — but the duplication is real.

Collapsing it means importing disko's NixOS module so `fileSystems` is derived
from the layout. **That is not done, on purpose:** disko would emit
`/dev/disk/by-partlabel/…` mounts, and on the current disk only partitions 1 and
2 carry partlabels (`EFI`, `root`). Partitions 3 (swap) and 4 (ExtNix) have none,
so the generated config would point at devices that do not exist and the machine
would not boot.

To enable it, add the two missing labels first — GPT metadata only, no data
touched — then switch over and reboot *while watching*:

```bash
sudo sgdisk -c 3:swap -c 4:ExtNix /dev/disk/by-id/ata-USSD_512GB_DTPP2409784000001014
ls /dev/disk/by-partlabel/    # expect EFI, root, swap, ExtNix
```

Note also that `disko.nix` describes a **fourth** partition, `ExtNix` (146.8 GB
exfat). `disko --mode destroy,format` will format it. Nothing in this repo backs
it up.

---

## 5. Genuinely not reproducible

- **Browser profile.** `modules/core/browser-policies.nix` now force-installs the
  17 extensions that were present, so a fresh profile gets them back. Their
  *settings* — uBlock filter lists, Dark Reader per-site rules, Vimium keys,
  Tampermonkey scripts — are still profile state. Export those separately from
  each extension if you care about them.
- **`~/.config/coderv2`** — Coder session tokens. Re-run `coder login`.
- **Shell history, `~/Music`, `~/Documents`, the ExtNix partition.** Data, not
  config. Back up as data.

---

## Restore order on a dead disk

1. Boot the ISO (`nix build .#iso`), run `install-nixos`. It runs disko, rewrites
   the mount UUIDs, and installs.
2. Restore the age key (§1) to `~/.config/sops/age/keys.txt`, mode 600.
3. Restore `/var/lib/sbctl` (§2), or re-enroll in firmware.
4. `sudo nixos-rebuild switch --flake .#portable` — secrets now materialize and
   Lanzaboote signs.
5. `tailscale up` if you have not added an auth key yet (§3).
6. `coder login`, then browser sign-ins.
