{ ... }:
{
  security = {
    rtkit.enable = true;
    sudo.enable = true;

    # swaylock authenticates via PAM. NixOS has no "swaylock" PAM service by
    # default, so we declare an (empty) one — it inherits NixOS's standard
    # password auth stack. WITHOUT this, swaylock rejects every password and you
    # are locked out of your own session. (Was hyprlock before the sway migration.)
    pam.services.swaylock = { };
  };
}
