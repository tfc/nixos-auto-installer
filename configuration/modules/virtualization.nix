{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (config.nixpkgs) hostPlatform;
in
{
  boot.binfmt.emulatedSystems =
    lib.optional (!hostPlatform.isx86_64) "x86_64-linux"
    ++ lib.optional (!hostPlatform.isAarch64) "aarch64-linux"
    # runs .exe files (e.g. pkgsCross.mingwW64 builds) via wine
    ++ lib.optional hostPlatform.isx86_64 "x86_64-windows";

  boot.extraModprobeConfig = ''
    options kvm-intel nested=Y
    options kvm-amd nested=1
  '';

  environment.systemPackages = with pkgs; [
    gnome-boxes
    libvirt
    virt-manager
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };
}
