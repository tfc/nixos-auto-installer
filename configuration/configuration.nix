{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/desktop-responsiveness.nix
    ./modules/firmware.nix
    ./modules/nix.nix
    ./modules/nixcademy-branding.nix
    ./modules/nixos-test-containers.nix
    ./modules/save-space.nix
    ./modules/training-tools.nix
    ./modules/virtualization.nix
    ./modules/zram.nix
  ];

  networking.hostName = "nixos-training";

  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.firewall.logRefusedConnections = false;
  networking.networkmanager.enable = true;

  services.avahi = {
    enable = true;
    ipv4 = true;
    ipv6 = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      domain = true;
      addresses = true;
    };
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  security.sudo.wheelNeedsPassword = false;
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.mutableUsers = false;
  users.users.root.password = "nixcademy";

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
