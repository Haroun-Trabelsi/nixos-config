# Recovery: what this repo cannot rebuild

`nix flake check` proves both machines *build*. It says nothing about whether you
could get back to a working machine from a dead disk. This file is the list of
state that lives outside git, ranked by how badly its loss hurts, and the order
to restore it in.

Everything below was inventoried on 2026-09-10 against the live system. Keep it
current — a runbook that has drifted is worse than none.

Ranked by consequence, the state that is NOT recoverable from this repo is: the
age key (§1, backed up off-machine), the Secure Boot PKI (§2, back it up), the
Tailscale node identity (§3, non-reproducible by design), and browser/extension
settings plus data partitions (§5, back up as data).

> **This repository is public** (`github.com/Haroun-Trabelsi/nixos-config`).
> Nothing secret goes in it beyond what is already age-encrypted, and the
> Secure Boot PKI deliberately does **not** go in it at all. See §2.

---

## 1. The age key

**`~/.config/sops/age/keys.txt`** (public half `age1pv00slc…`, the recipient in
`.sops.yaml`).

Everything in `secrets/secrets.yaml` is encrypted to it — the GitHub SSH key, the
GitHub PAT, the Spotify VPN key — and so is `secrets/bitwarden_backup.age`
(verified, not assumed). It is not derivable from anything in this repo.

**Status: a copy is held off this machine.** That is the whole requirement, and
it closes the one failure that would otherwise be unrecoverable. It also settles
the `bitwarden_backup.age` question: that file being encrypted to the same key
only mattered while the key existed nowhere but this disk. With an off-machine
copy the key is retrievable independently of the disk, so the blob needs no
re-encryption and there is no reason to add a second recipient.

The only thing left worth doing is confirming the copy actually works, since an
untested backup is a hypothesis rather than a backup:

```bash
# Should print the same public key as .sops.yaml lists.
nix shell nixpkgs#age -c age-keygen -y /path/to/your/backup/copy
```

On restore, it goes back to `~/.config/sops/age/keys.txt`, mode 600.

`sops.age.sshKeyPaths` is **not** an option here: it needs an SSH host key, and
`services.openssh` is not enabled on either machine, so `/etc/ssh/ssh_host_*_key`
does not exist.

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

### What a fresh install actually creates

`disko.nix` defaults to the minimum: **a 1 GiB ESP and root across the rest of
the disk.** Nothing else. Two switches at the top of the file turn the extras on,
and both are off:

- `enableSwap` — no swap partition by default. The laptop's `zramSwap` (50% of
  RAM) covers routine paging without touching the USB link, and hibernation is
  already ruled out on this hardware, so a swap partition buys nothing. The
  current disk still has a 17 GiB one from before that reasoning; it is barely
  touched. `swapDevices` in `hardware-shared.nix` carries `nofail`, and the
  installer empties the list outright when the target disk has no swap, so a
  swapless install boots cleanly with no hand-editing.
- `enableDataPartition` — no exfat data partition by default. `ExtNix` on the
  current disk is 146.8 GB of storage, not part of the system, and a destructive
  installer should not carve a third of a new disk away without being asked. If
  you do turn it on, note that `disko --mode destroy,format` formats it: it is
  not a place to keep the only copy of anything.

Turning `enableDataPartition` on also drops root from `100%` to `312G`, which is
what the current disk looks like.

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
2. Restore the age key (§1) from your off-machine copy to
   `~/.config/sops/age/keys.txt`, mode 600.
3. Restore `/var/lib/sbctl` (§2), or re-enroll in firmware.
4. `sudo nixos-rebuild switch --flake .#portable` — secrets now materialize and
   Lanzaboote signs.
5. `tailscale up` if you have not added an auth key yet (§3).
6. `coder login`, then browser sign-ins.
