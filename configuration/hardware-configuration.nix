{
  modulesPath,
  lib,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot.loader.systemd-boot.enable = true;

  boot.kernelModules = [
    "kvm-intel"
    "kvm-amd"
  ];

  boot.initrd.kernelModules = [
    "virtio_balloon"
    "virtio_console"
    "virtio_rng"
  ];

  boot.initrd.availableKernelModules = [
    "9p"
    "9pnet_virtio"
    "ata_piix"
    "nvme"
    "sr_mod"
    "uhci_hcd"
    "virtio_blk"
    "virtio_mmio"
    "virtio_net"
    "virtio_pci"
    "virtio_scsi"
    "xhci_pci"
  ];

  # Partitions created by disko.nix in the installer
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/disk-main-ESP";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/disk-main-root";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-partlabel/disk-main-swap"; } ];

  networking.useDHCP = lib.mkDefault true;
}
