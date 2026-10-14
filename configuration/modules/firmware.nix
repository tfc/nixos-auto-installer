{ lib, pkgs, ... }:

{
  hardware.cpu.intel.updateMicrocode = lib.mkDefault pkgs.stdenv.hostPlatform.isx86_64;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault pkgs.stdenv.hostPlatform.isx86_64;
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  nixpkgs.config.allowUnfree = true;
  services.fwupd.enable = true;
}
