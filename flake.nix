{
  description = "NixOS Offline Auto Installer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko.url = "github:nix-community/disko";
    disko.flake = false;
  };

  outputs = inputs: {
    nixosConfigurations.installer = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        ./installer.nix
        "${inputs.disko}/module.nix"
      ];
    };
    nixosConfigurations.installed = inputs.nixpkgs.lib.nixosSystem {
      modules = [ ./configuration/configuration.nix ];
    };

    packages = builtins.mapAttrs (system: pkgs: {
      default = inputs.self.packages.${system}.installer-iso;
      installer-iso = inputs.self.nixosConfigurations.installer.config.system.build.isoImage;

      install-demo = pkgs.writeShellScriptBin "install-demo" ''
        set -euo pipefail
        disk=root.img
        if [ ! -f "$disk" ]; then
          echo "Creating harddisk image root.img"
          ${pkgs.qemu}/bin/qemu-img create -f qcow2 "$disk" 40G
        else
          echo "Reusing existing disk"
        fi
        # Both stay attached: OVMF tries the disk first and falls through to
        # the installer ISO as long as the disk has no bootloader, so the
        # first run installs and later runs boot the installed system.
        ${pkgs.qemu}/bin/qemu-system-x86_64 \
          -machine q35 -accel kvm \
          -cpu host \
          -m 2G \
          -smp 4 \
          -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          -drive if=none,id=disk,format=qcow2,file="$disk" \
          -device ide-hd,drive=disk,bus=ide.0,bootindex=1 \
          -drive if=none,id=iso,media=cdrom,readonly=on,file=${
            inputs.self.packages.${system}.installer-iso
          }/${inputs.self.nixosConfigurations.installer.config.image.filePath} \
          -device ide-cd,drive=iso,bus=ide.1,bootindex=2 \
          "$@"
      '';
    }) inputs.nixpkgs.legacyPackages;

    # `nix run` boots the installer ISO in a VM, `nix build` still builds the ISO.
    apps = builtins.mapAttrs (system: _: {
      default = {
        type = "app";
        program = inputs.nixpkgs.lib.getExe inputs.self.packages.${system}.install-demo;
        meta.description = "Boot root.img in a QEMU VM, installing it from the auto-installer ISO first if it isn't bootable yet";
      };
    }) inputs.nixpkgs.legacyPackages;

    devShells = builtins.mapAttrs (system: pkgs: {
      default = pkgs.mkShell {
        packages = [ inputs.self.formatter.${system} ];
      };
    }) inputs.nixpkgs.legacyPackages;

    formatter = builtins.mapAttrs (
      _: pkgs:
      pkgs.treefmt.withConfig {
        settings = {
          tree-root-file = "flake.nix";
          on-unmatched = "info";
          formatter = {
            nixfmt = {
              command = pkgs.lib.getExe pkgs.nixfmt;
              includes = [ "*.nix" ];
            };
            statix = {
              command = pkgs.lib.getExe pkgs.statix;
              options = [ "fix" ];
              no-positional-arg-support = true;
              includes = [ "*.nix" ];
            };
            deadnix = {
              command = pkgs.lib.getExe pkgs.deadnix;
              options = [ "--edit" ];
              includes = [ "*.nix" ];
            };
            prettier = {
              command = pkgs.lib.getExe pkgs.prettier;
              options = [ "--write" ];
              includes = [
                "*.css"
                "*.html"
                "*.js"
                "*.json"
                "*.md"
                "*.yaml"
                "*.yml"
              ];
            };
            shfmt = {
              command = pkgs.lib.getExe pkgs.shfmt;
              options = [
                "-w"
                "-i"
                "2"
                "-s"
              ];
              includes = [
                "*.sh"
                "*.bash"
                "*.envrc"
                "*.envrc.*"
              ];
            };
          };
        };
      }
    ) inputs.nixpkgs.legacyPackages;

    checks = builtins.mapAttrs (system: _: {
      formatting = inputs.self.formatter.${system}.check inputs.self;
    }) inputs.nixpkgs.legacyPackages;
  };
}
