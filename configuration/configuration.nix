{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/desktop-responsiveness.nix
    ./modules/firmware.nix
    ./modules/german.nix # for trainings in Germany
    ./modules/nix.nix
    ./modules/nixcademy-branding.nix
    ./modules/nixos-test-containers.nix
    ./modules/save-space.nix
    ./modules/size-reduction.nix
    ./modules/training-tools.nix
    ./modules/virtualization.nix
    ./modules/zram.nix
  ];

  networking.hostName = "nixos-training";

  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    }
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.firewall.logRefusedConnections = false;
  networking.networkmanager.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    settings.publish = {
      disable-publishing = false;
      publish-domain = true;
      publish-addresses = true;
    };
  };

  services.bootvine.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  security.sudo.wheelNeedsPassword = false;
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.mutableUsers = false;
  users.users.root.password = "nixcademy";

  customization.user-icon.users = [ "nixcademy" ];

  users.users.nixcademy = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "kvm"
      "libvirtd"
    ];
    initialPassword = "nixcademy";
  };

  system.stateVersion = "26.11";
}
