{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
let
  # can't use pkgs.nixos because we're setting nixpkgs config settings
  # (at least allowUnfree) in install config.
  evaluatedSystem = import (pkgs.path + "/nixos/lib/eval-config.nix") {
    system = null; # nixpkgs.hostPlatform is set in hardware-configuration.nix
    modules = [ ./configuration/configuration.nix ];
  };

  select-install-disk = pkgs.writeShellApplication {
    name = "select-install-disk";
    runtimeInputs = [
      pkgs.jq
      pkgs.util-linux
    ];
    text = builtins.readFile ./select-install-disk.sh;
  };

  # The installed system doesn't import disko, so its mounts are written by
  # hand. Make sure they match what disko creates.
  # disko returns its config as lib.mkMerge values
  unmerge = x: if x._type or null == "merge" then x.contents else [ x ];
  diskoFileSystems = lib.mergeAttrsList (unmerge config.disko.devices._config.fileSystems);
  diskoSwapDevices = lib.concatLists (unmerge config.disko.devices._config.swapDevices);
  installed = evaluatedSystem.config;
  mountsMatch =
    lib.all (
      mp:
      diskoFileSystems.${mp}.device == installed.fileSystems.${mp}.device
      && diskoFileSystems.${mp}.fsType == installed.fileSystems.${mp}.fsType
    ) (builtins.attrNames diskoFileSystems)
    && map (s: s.device) diskoSwapDevices == map (s: s.device) installed.swapDevices;
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ./disko.nix
  ];

  # Only use disko's format/mount scripts, don't mount anything on the ISO itself.
  disko.enableConfig = false;

  assertions = [
    {
      assertion = mountsMatch;
      message = "fileSystems/swapDevices in configuration/hardware-configuration.nix don't match disko.nix";
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  image.fileName = lib.mkForce "nixcademy-auto-installer-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  services.getty.helpLine = ''
    ███╗   ██╗██╗██╗  ██╗ ██████╗ █████╗ ██████╗ ███████╗███╗   ███╗██╗   ██╗
    ████╗  ██║██║╚██╗██╔╝██╔════╝██╔══██╗██╔══██╗██╔════╝████╗ ████║╚██╗ ██╔╝
    ██╔██╗ ██║██║ ╚███╔╝ ██║     ███████║██║  ██║█████╗  ██╔████╔██║ ╚████╔╝
    ██║╚██╗██║██║ ██╔██╗ ██║     ██╔══██║██║  ██║██╔══╝  ██║╚██╔╝██║  ╚██╔╝
    ██║ ╚████║██║██╔╝ ██╗╚██████╗██║  ██║██████╔╝███████╗██║ ╚═╝ ██║   ██║
    ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝     ╚═╝   ╚═╝

    Automatic Installer Go brrrrr
  '';

  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;

  services.journald.settings.Journal = {
    ForwardToConsole = true;
    TTYPath = "/dev/tty1";
  };

  nix.settings.substituters = lib.mkForce [ ];

  systemd.services.install = {
    description = "Bootstrap a NixOS installation";
    wantedBy = [ "multi-user.target" ];
    after = [ "polkit.service" ];
    path = [ "/run/current-system/sw/" ];
    script = ''
      # this is just for debugging purposes, can be removed when it all works
      echo 'journalctl -fb -n100 -uinstall' >> ~nixos/.bash_history

      set -euxo pipefail

      INSTALL_DISK=$(${lib.getExe select-install-disk})
      if [ -z "$INSTALL_DISK" ]; then
        echo 'No built-in disk found, refusing to install. Block devices:'
        lsblk -o NAME,TYPE,SIZE,RM,HOTPLUG,RO,TRAN,MODEL
        exit 1
      fi
      export INSTALL_DISK

      echo "Installing to /dev/$INSTALL_DISK, ALL DATA ON IT WILL BE LOST:"
      lsblk -o NAME,SIZE,TRAN,MODEL "/dev/$INSTALL_DISK"
      for i in $(seq 10 -1 1); do
        echo "Wiping in $i seconds, pull the USB stick to abort..."
        sleep 1
      done

      ${config.system.build.destroyFormatMount}/bin/disko-destroy-format-mount --yes-wipe-all-disks

      mkdir -p /mnt/etc/nixos
      cp -r ${./configuration}/* /mnt/etc/nixos/
      chmod -R u+w /mnt/etc/nixos

      # add parameters so that nix does not try to contact a cache as we expect
      # to be offline anyway
      ${config.system.build.nixos-install}/bin/nixos-install \
        --system ${evaluatedSystem.config.system.build.toplevel} \
        --no-root-passwd \
        --cores 0

      echo 'Done. Shutting off.'
      systemctl poweroff
    '';
    environment = config.nix.envVars // {
      inherit (config.environment.sessionVariables) NIX_PATH;
      HOME = "/root";
    };
    serviceConfig = {
      Type = "oneshot";
    };
  };

}
