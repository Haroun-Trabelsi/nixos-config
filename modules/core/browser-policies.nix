{ ... }:
{
  # Thorium is a Chromium fork and reads managed policy from /etc/chromium/policies
  # (verified with `strings` on the binary), so this applies to it as well as to
  # any other Chromium here. Chromium merges every json file in the directory, and
  # NixOS' own programs.chromium writes default.json, hence the distinct name.
  #
  # Without this, the first claude-plan:// link from the Linear bookmarklet raises
  # the "open external application?" dialog. Ticking its "always allow" box is
  # profile state, which nothing in this repo manages — this makes it declarative,
  # and scopes the auto-launch to linear.app only.
  environment.etc."chromium/policies/managed/linear-plan.json".text =
    builtins.toJSON
      {
        AutoLaunchProtocolsFromOrigins = [
          {
            protocol = "claude-plan";
            allowed_origins = [ "https://linear.app" ];
          }
        ];
      };
}
