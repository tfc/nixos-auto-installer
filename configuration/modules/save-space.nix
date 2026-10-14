{ lib, ... }:

{
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 2;
  boot.tmp.cleanOnBoot = true;

  services.journald.settings.Journal = {
    SystemMaxUse = "250M";
    SystemMaxFileSize = "50M";
  };

  # super large.
  # We typically know upfront if we have trainings with people who need it.
  services.speechd.enable = lib.mkForce false;
}
