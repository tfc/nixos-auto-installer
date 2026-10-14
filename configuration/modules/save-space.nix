{ lib, ... }:

{
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 2;
  boot.tmp.cleanOnBoot = true;

  services.journald.settings.Journal = {
    SystemMaxUse = "250M";
    SystemMaxFileSize = "50M";
  };
}
