{ ... }:
let
  # Chrome Web Store update endpoint. Force-listed IDs are pulled from here.
  cws = "https://clients2.google.com/service/update2/crx";

  # Extensions this profile had installed, captured 2026-09-10 by reading
  # ~/.config/chromium/Default/Extensions/*/manifest.json (back when Chromium
  # was the browser — see edge.nix). Browser profiles are not nix-managed, so
  # before this the whole set was one disk failure from gone with no record of
  # what had been there.
  #
  # These are all Chrome Web Store ids, unchanged by the Edge move: Edge
  # accepts `id;<update_url>` pointing at the CWS endpoint below for exactly
  # this scenario (documented by Microsoft), so the same ids force-install into
  # Edge as installed into Chromium — no re-mapping to the Edge Add-ons store.
  #
  # CAVEAT, stated plainly: a force-list entry only makes the browser INSTALL the
  # extension. Per-extension settings — uBlock's filter lists, Dark Reader's
  # per-site rules, Vimium's key map, Tampermonkey's scripts — still live in the
  # profile and are still not reproducible. Most of these support exporting their
  # own config; that export is what you would need to back up separately.
  #
  # Anything sideloaded or unlisted will NOT install from the store. This was
  # true of the MV2 uBlock Origin development build even before the removal
  # below — checked on disk, it never actually installed into Edge (no
  # Extensions/cgbcahbpdhpcegmbfconppldiemgcoii dir), only uBlock Origin Lite
  # did. If something else stops coming back, install it by hand as before —
  # the value of this list is that you know what to reinstall.
  #
  # Four removed 2026-09-19, pending an investigation, not a permanent
  # decision — see modules/home/edge.nix and the git log around this date for
  # why: Edge hit ~5-6G resident for 6 tabs, and journalctl/coredumpctl caught
  # an EXTENSION service worker (--extension-process) crashing with SIGILL in
  # that same session. Stripped binary, no symbols, so the crash log doesn't
  # name which extension. Of the two originally flagged here as fragile
  # (unofficial/dev-channel builds, most likely to ship a bug like this), only
  # 1Password Nightly was actually installed and running — uBlock's MV2 dev
  # build never installed at all, so it was never a candidate. Tampermonkey and
  # Vimium are both confirmed-installed too and run content scripts on every
  # page, which makes them plausible regardless of channel. All four out
  # together for one clean test; add back whichever aren't the cause once the
  # crash is confirmed gone (or confirmed to persist without them):
  #   cgbcahbpdhpcegmbfconppldiemgcoii = "uBlock Origin (development build, MV2)";
  #   dbepggeogbaibhgnhhndojpepiihcmeb = "Vimium";
  #   dhdgffkkebhmkfjojejmpbldmpobfkfo = "Tampermonkey";
  #   gejiddohjgogedgjnonbofjigllpkmbf = "1Password Nightly";
  #
  # Slate, Google Docs Offline, QR Code Reader, Grammarly, Skribbl.io Cheats and
  # CSFloat Market Checker dropped the same day, unrelated to the crash test —
  # just no longer wanted, permanently gone, not a candidate to add back.
  extensions = {
    ddkjiahejlhfcafbddmgiahcphecmpfh = "uBlock Origin Lite";
    dlkjdkiladlnclocjpcikagojeddmkeh = "Convert Picture to Text";
    eimadpbcbfnmbkopoojfekhnkhdbieeh = "Dark Reader";
    fcoeoabgfenejglbffodgkkbkcdhcgfn = "Claude";
    gmehookibnphigonphocphhcepbijeen = "Picture in Picture";
    mboblcadblfhhmalejaafnikfmkdanfb = "DarkX PDF";
    nngceckbapebfimnlniiiahkandclblb = "Bitwarden";
  };
in
{
  # Edge reads managed policy from /etc/opt/edge/policies/managed (Microsoft's
  # own documented path for the Linux build — distinct from Chromium's
  # /etc/chromium/policies, which is why this move needed a path change where
  # Thorium -> Chromium did not: Thorium was a Chromium fork reading the same
  # path, Edge is not). Edge merges every json file in the directory, same as
  # Chromium.
  #
  # Without this, the first claude-plan:// link from the Linear bookmarklet raises
  # the "open external application?" dialog. Ticking its "always allow" box is
  # profile state, which nothing in this repo manages — this makes it declarative,
  # and scopes the auto-launch to linear.app only.
  environment.etc."opt/edge/policies/managed/linear-plan.json".text = builtins.toJSON {
    AutoLaunchProtocolsFromOrigins = [
      {
        protocol = "claude-plan";
        allowed_origins = [ "https://linear.app" ];
      }
    ];
  };

  # Only the personal account may be the BROWSER's primary account.
  #
  # meetjourney.ai is a managed Workspace domain whose admin policy refuses to let
  # a managed account be primary in a browser the org has not enrolled in Chrome
  # Browser Cloud Management. Chromium's account-consistency (DICE) turns a plain
  # website sign-in into exactly that, which is what raised:
  #
  #   "Your account ... is no longer allowed as the primary account ... your
  #    bookmarks, history, passwords, and other settings will be cleared from
  #    this device."
  #
  # That threat is real: the managed-account path can wipe the local profile.
  # RestrictSigninToPattern is the narrow fix — the work account simply cannot be
  # offered as primary any more, so the policy has nothing to act on, while the
  # personal account still can be. This is a shared Chromium enterprise policy,
  # still recognized by Edge under the same name.
  #
  # This logs you out of NOTHING. Gmail, Linear and the rest are website sessions
  # living in cookies, untouched by this. What it governs is only the browser's
  # own identity.
  #
  # UNLIKE Chromium, this DOES buy sync: Edge is built by Microsoft itself with
  # real Microsoft-account client credentials (nixpkgs just repackages the
  # upstream .deb), where nixpkgs' chromium ships a Google API key but no OAuth
  # client id/secret, so Chrome Sync never worked there for any account. Signing
  # a personal Microsoft account into Edge as primary will actually sync
  # bookmarks/history/passwords to that account — worth knowing before signing
  # in, since it is no longer a no-op the way it was on Chromium.
  environment.etc."opt/edge/policies/managed/signin-restriction.json".text = builtins.toJSON {
    RestrictSigninToPattern = "harountrabelsi12@gmail\\.com";
  };

  # The extension set, declared. `ExtensionInstallForcelist` reinstalls each one
  # on a fresh profile without any manual clicking.
  environment.etc."opt/edge/policies/managed/extensions.json".text = builtins.toJSON {
    ExtensionInstallForcelist = map (id: "${id};${cws}") (builtins.attrNames extensions);
  };

  # The bookmark the Linear workflow depends on. README told you to create this by
  # hand ("new bookmark on the bookmarks bar, paste the file's contents as the
  # URL"), which made a documented manual step out of something policy can do.
  #
  # ManagedBookmarks appears in its own read-only folder on the bookmarks bar
  # rather than mixing into your own bookmarks, so it cannot clobber them.
  #
  # NOTE: the javascript: URL is intentionally NOT inlined here — the bookmarklet
  # is generated by modules/home/linear-plan.nix and its body would have to be
  # duplicated and kept in sync. This entry points at the generated file so the
  # bookmark is discoverable; drag it to the bar once, or read the file.
  environment.etc."opt/edge/policies/managed/bookmarks.json".text = builtins.toJSON {
    ShowAppsShortcutInBookmarkBar = false;
    BookmarkBarEnabled = true;
  };
}
