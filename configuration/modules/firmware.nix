{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Intel microcode only on x86 hosts where nothing else enabled AMD microcode.
  hardware.cpu.intel.updateMicrocode = lib.mkDefault (
    pkgs.stdenv.hostPlatform.isx86_64 && !config.hardware.cpu.amd.updateMicrocode
  );
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  nixpkgs.config.allowUnfree = true; # needed by the unfree firmware blobs
  services.fwupd.enable = true;
}
