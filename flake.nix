{
  description = "NixOS Offline Auto Installer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = inputs: {
    nixosConfigurations.installer = inputs.nixpkgs.lib.nixosSystem {
      modules = [ ./installer.nix ];
    };
    nixosConfigurations.installed = inputs.nixpkgs.lib.nixosSystem {
      modules = [ ./configuration/configuration.nix ];
    };

    packages = builtins.mapAttrs (system: pkgs: {
      default = inputs.self.packages.${system}.installer-iso;
      installer-iso = inputs.self.nixosConfigurations.installer.config.system.build.isoImage;

      install-demo = pkgs.writeShellScript "install-demo" ''
        set -euo pipefail
        disk=root.img
        if [ ! -f "$disk" ]; then
          echo "Creating harddisk image root.img"
          ${pkgs.qemu}/bin/qemu-img create -f qcow2 "$disk" 20G
        fi
        ${pkgs.qemu}/bin/qemu-system-x86_64 \
          -machine q35 -accel kvm \
          -cpu host \
          -enable-kvm \
          -m 2G \
          -smp 4 \
          -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          -cdrom ${inputs.self.packages.${system}.installer-iso}/iso/*.iso \
          -hda "$disk"
      '';
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
