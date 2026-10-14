{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/firmware.nix
    ./modules/nix-unstable.nix
    ./modules/flakes.nix
    ./modules/nixcademy-branding.nix
    ./modules/save-space.nix
    ./modules/virtualization.nix
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

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    tmux
    unzip
  ];

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
