# nixos-auto-installer

Build recipe for an unattended, offline capable USB-bootable NixOS installer to bootstrap random computers.

I typically use this to "transform" random computers to minimally setup NixOS machines by putting in my USB stick and boot from it.
Afterward, the machine can be rebootet and then i can deploy whatever config i want over it from remote via SSH.
The system is really just meant as a trampoline for installing "real" system configs from remote.

## Usage

**Warning:** The created USB stick is destructive in the sense that it deletes everything on the disk without asking!

1. Build the ISO image via `nix build`
2. `dd` the ISO image over a USB stick
3. Put the USB stick into a machine that is set up to boot via USB
4. Let the machine boot and wait until it powers off again. (It typically takes ~5 minutes)
5. NixOS is now installed. Just SSH into it.

## Installation Scheme

The installer [partitions the disk](https://github.com/tfc/nixos-auto-installer/blob/main/installer.nix#L35) like this:

- 512 MiB fat32 boot partition
- 8 GiB swap partition
- rest size ext4  nixos partition

The `root` user is the only user on the system. It has no password for physical login.
The only way to login is via SSH with pubkey authentication (see Customization in this README).

Unfree modules for wifi are added in order to enable the machine's wifi on first boot.

Only SSH is installed as a service.

## Customization

### SSH Access

Add your SSH key [here](https://github.com/tfc/nixos-auto-installer/blob/main/configuration.nix#L28)

### WiFi

Add a wifi config to `configuration.nix` to let the machine automatically into your wifi after installation:

```nix
  networking.wireless = {
    enable = true;
    networks."my-wifi-name".psk = "my-wifi-password";
    userControlled.enable = true;
  };
```

There are different ways to add passwords to a machine, and *this* is not a secure one as the password will be stored in the nix store.
(Which is fine for *my* purposes, but maybe not yours)
