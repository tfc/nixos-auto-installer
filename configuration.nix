{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];
  nixpkgs.config.allowUnfree = true;
  networking.hostName = "nixos-bootstrap";
  services.avahi = {
    enable = true;
    ipv4 = true;
    ipv6 = true;
    nssmdns = true;
    publish = { enable = true; domain = true; addresses = true; };
  };
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    tmux
  ];

  security.sudo.wheelNeedsPassword = false;
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIManOIJLP/sPj7glqo6R1+6+oJJToiNxtbHOLPPU187y tfc@jongebook"
  ];
}
