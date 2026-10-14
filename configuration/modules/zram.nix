# stolen and adapted from connor bakers config: https://github.com/ConnorBaker/nixos-configs
{ lib, ... }:
{
  # Tune the configuration to take advantage of the ZRAM swap device.
  boot.kernel.sysctl = {
    # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
    # Reclaim earlier and in bigger batches so we compress ahead of demand
    # instead of stalling allocators once memory is already tight.
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    # Swapping to RAM has no seek cost, so reading whole 8-page clusters
    # around a fault only wastes decompression work. 0 = read one page.
    "vm.page-cluster" = 0;

    # https://github.com/pop-os/default-settings/blob/master_noble/etc/sysctl.d/10-pop-default-settings.conf
    # Anon pages go to zram (cheap) while file pages would have to be re-read
    # from disk, so bias reclaim hard towards anon. Only sane *because* zram
    # is the highest-priority swap device. Hosts that would rather keep pages
    # resident (battery, NVMe wear) override this.
    "vm.swappiness" = lib.mkDefault 190;
  };

  zramSwap = {
    algorithm = "zstd";
    enable = true;

    # Percent of RAM as *uncompressed* device size. Measured zstd ratio on a
    # typical desktop working set is ~3.5:1, so a full 200% device costs a bit
    # over half of RAM in real pages. Connor's 400% assumes builders with much
    # more headroom: at that ratio it wants more RAM than the box has, which
    # is exactly the OOM in the TODO below. Override per host.
    memoryPercent = lib.mkDefault 200;

    # TODO: Consider a writeback device to avoid OOMs.
    # https://wiki.archlinux.org/title/Zram#Enabling_a_backing_device_for_a_zram_block
  };
}
