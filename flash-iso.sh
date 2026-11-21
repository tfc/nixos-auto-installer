# Flash the installer ISO (path in $ISO) onto a USB stick.
# Usage: flash-iso [/dev/sdX]
# Without an argument, the stick is detected: a whole, writable, removable
# disk on USB that fits the ISO. Either way, nothing is written without a "y".

iso_size=$(stat -L -c %s "$ISO")

echo "Disks:"
lsblk --nodeps -o NAME,SIZE,TRAN,RM,HOTPLUG,RO,MODEL -e 7 # 7 = loop devices
echo

if [ $# -gt 0 ]; then
  dev=$1
else
  mapfile -t candidates < <(
    lsblk --json --bytes --nodeps -o NAME,TYPE,SIZE,RM,HOTPLUG,RO,TRAN |
      jq -r --argjson min "$iso_size" '
        .blockdevices[]
        | select(
            .type == "disk"
            and .tran == "usb"
            and (.rm or .hotplug)
            and (.ro | not)
            and .size >= $min
          )
        | "/dev/" + .name
      '
  )
  case ${#candidates[@]} in
  0)
    echo "No USB stick found that fits the ISO ($(numfmt --to=iec "$iso_size"))." >&2
    echo "Plug one in, or pass the device explicitly: flash-iso /dev/sdX" >&2
    exit 1
    ;;
  1) dev=${candidates[0]} ;;
  *)
    echo "Several USB sticks found: ${candidates[*]}" >&2
    echo "Pass the one to flash explicitly: flash-iso /dev/sdX" >&2
    exit 1
    ;;
  esac
fi

if [ "$(lsblk -dno TYPE "$dev" 2>/dev/null)" != disk ]; then
  echo "$dev is not a whole disk." >&2
  exit 1
fi

echo "ISO:    $ISO ($(numfmt --to=iec "$iso_size"))"
echo "Target: $dev"
lsblk -o NAME,SIZE,TRAN,MODEL,LABEL,MOUNTPOINTS "$dev"
echo
read -r -p "ALL DATA ON $dev WILL BE LOST. Flash it? [y/N] " answer
if [ "$answer" != y ]; then
  echo "Aborted."
  exit 1
fi

sudo=()
if [ "$(id -u)" -ne 0 ]; then
  sudo=(sudo)
  # Ask for the password now, not in the middle of the progress bar.
  sudo -v
fi

# Desktops automount sticks; writing under a mounted filesystem corrupts it.
while read -r part; do
  if findmnt -rn -S "$part" >/dev/null; then
    echo "Unmounting $part"
    "${sudo[@]}" umount "$part"
  fi
done < <(lsblk -nro PATH "$dev")

pv --size "$iso_size" "$ISO" |
  "${sudo[@]}" dd of="$dev" bs=4M iflag=fullblock oflag=direct conv=fsync status=none

echo "Done. $dev can be unplugged."
