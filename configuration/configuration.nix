{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/firmware.nix
    ./modules/nix-unstable.nix
    ./modules/flakes.nix
    ./modules/nixcademy-gdm-logo.nix
    ./modules/nixcademy-gnome-background.nix
    ./modules/nixcademy-plymouth-logo.nix
    ./modules/save-space.nix
    ./modules/virtualization.nix
  ];

  nixpkgs.config.allowUnfree = true;

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
    publish = { enable = true; domain = true; addresses = true; };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    tmux
    unzip
  ];

  services.xserver = {
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
    enable = true;
    libinput.enable = true;
  };

  boot.plymouth.enable = true;

  customization = {
    gdm-logo.enable = true;
    gnome-background.enable = true;
    plymouth-logo.enable = true;
  };

  hardware.opengl = {
    # this fixes the "glXChooseVisual failed" bug,
    # context: https://github.com/NixOS/nixpkgs/issues/47932
    enable = true;
    driSupport32Bit = true;
  };

  security.sudo.wheelNeedsPassword = false;
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.mutableUsers = false;
  users.extraUsers.root.password = "nixcademy";

  users.users.nixcademy = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "kvm"
    ];
    initialPassword = "nixcademy";
  };
}
