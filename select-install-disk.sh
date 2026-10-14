# Print the kernel name of the biggest built-in disk, e.g. "nvme0n1".
# Built-in means: a whole, writable, non-removable disk on an internal bus
# (or a virtio disk), that is not the medium the installer booted from.

min_size=$((32 * 1024 * 1024 * 1024))

boot_disk=""
if iso_source=$(findmnt -no SOURCE /iso 2>/dev/null); then
  boot_disk=$(lsblk -no PKNAME "$iso_source" | head -n1)
  # isohybrid images put the ISO filesystem on the whole device
  boot_disk=${boot_disk:-$(basename "$iso_source")}
fi

lsblk --json --bytes --nodeps -o NAME,TYPE,SIZE,RM,HOTPLUG,RO,TRAN,MODEL |
  jq -r --arg boot "$boot_disk" --argjson min "$min_size" '
    .blockdevices
    | map(select(
        .type == "disk"
        and (.rm | not)
        and (.hotplug | not)
        and (.ro | not)
        and ((.tran | IN("nvme", "sata", "ata", "sas")) or (.name | test("^vd")))
        and .name != $boot
        and .size >= $min
      ))
    | max_by(.size)
    | .name // empty
  '
