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
    ++ lib.optional (!hostPlatform.isAarch64) "aarch64-linux";

  boot.extraModprobeConfig =
    if config.hardware.cpu.intel.updateMicrocode then
      "options kvm-intel nested=Y"
    else if config.hardware.cpu.amd.updateMicrocode then
      "options kvm-amd nested=1"
    else
      "";

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
