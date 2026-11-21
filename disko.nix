{
  disko.devices.disk.main = {
    type = "disk";
    # Expanded by bash when the disko script runs: the installer exports the
    # chosen disk's kernel name, e.g. INSTALL_DISK=nvme0n1.
    device = "/dev/\${INSTALL_DISK}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        # Raw partition used as zram's writeback device (see
        # configuration/modules/zram.nix), not as swap. Without content it
        # gets the generic "Linux filesystem" type (8300), so
        # systemd-gpt-auto-generator doesn't swapon it before zram claims it.
        zram-writeback = {
          size = "8G";
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
