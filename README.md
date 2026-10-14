# nixos-auto-installer

Unattended, offline capable USB-bootable NixOS installer to bootstrap random computers.

We typically use this to bootstrap customer laptops that are meant for Nix training use.
The workflow is that we visit the customer for a multi day training, hand out USB sticks with this installer, and ask participants to boot from the stick.
Depending on the USB performance, the laptop is initialized within a short time and shuts down.

The system content is customized for our trainings but can be adapted to something else.

## Usage

**Warning:**
The created USB stick is destructive in the sense that it deletes everything on the disk without asking!

1. Build the ISO image via `nix build`
2. `dd` the ISO image over a USB stick
3. Put the USB stick into a machine that is set up to boot via USB
4. Let the machine boot and wait until it powers off again.
   (It typically takes ~5-20 minutes, depending on the speed of the USB port)
5. NixOS is now installed.

The system also carries its own NixOS configuration.
This way you can `nixos-rebuild` locally for updates and changes.

## Installation Scheme

The installer installs to the biggest built-in disk (see [`select-install-disk.sh`](./select-install-disk.sh)).
If there is no such disk, it refuses to install.
It shows the chosen disk and waits 10 seconds before wiping it, so pulling the USB stick aborts the installation.

The disk is then partitioned like this:

- 512 MiB fat32 boot partition
- 8 GiB swap partition
- rest size ext4 nixos partition

The system provides a user `nixcademy`.
The password is `nixcademy` for both this account and the `root` account.

Unfree modules for wifi are added to enable the machine's wifi on first boot.

Only SSH is installed as a service.

## Customization

### WiFi

Add a wifi config to [`configuration.nix`](./configuration/configuration.nix) to let the machine automatically into your wifi after installation:

```nix
  networking.wireless = {
    enable = true;
    networks."my-wifi-name".psk = "my-wifi-password";
    userControlled.enable = true;
  };
```

There are different ways to add passwords to a machine, and _this_ is not a secure one as the password will be stored in the nix store.
(Which is fine for _my_ purposes, but maybe not yours)
