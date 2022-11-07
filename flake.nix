{
  description = "NixOS Offline Auto Installer";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , flake-parts
    , nixpkgs
    , pre-commit-hooks
    }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = [ "x86_64-linux" ];
      perSystem = { config, system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          devShells.default = pkgs.mkShell {
            shellHook = ''
              ${config.checks.pre-commit-check.shellHook}
            '';
          };

          packages = {
            default = config.packages.installer;
            installer = (pkgs.nixos [ ./installer.nix ]).config.system.build.isoImage;
            install-demo = pkgs.writeShellScript "install-demo" ''
              set -euo pipefail
              disk=root.img
              if [ ! -f "$disk" ]; then
                echo "Creating harddisk image root.img"
                ${pkgs.qemu}/bin/qemu-img create -f qcow2 "$disk" 20G
              fi
              ${pkgs.qemu}/bin/qemu-system-x86_64 \
                -cpu host \
                -enable-kvm \
                -m 2G \
                -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
                -cdrom ${config.packages.installer}/iso/*.iso \
                -hda "$disk"
            '';
          };

          checks = {
            pre-commit-check = pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                deadnix.enable = true;
                nixpkgs-fmt.enable = true;
                shellcheck.enable = true;
                shfmt.enable = true;
                statix.enable = true;
              };
            };
          };
        };
    };
}
