{
  lib,
  options,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    {
      nixpkgs.overlays = [
        (_: prev: {
          # Drop all firmware that's irrelevant on x86_64 laptops.
          linux-firmware = prev.linux-firmware.overrideAttrs (old: {
            postInstall = old.postInstall or "" + ''
              rm -rf $out/lib/firmware/{qcom,mellanox,mrvl/prestera,netronome,qed,dpaa2,cxgb4,bnx2x,liquidio,inside-secure}
              find $out/lib/firmware -xtype l -delete
            '';
          });
        })
      ];

      # pro: no aggressive MS ads and telemetry.
      # con: can't use the vscode-ssh stuff for the training cloud machine
      programs.vscode.package = pkgs.vscodium;

      # default fonts minus asian fonts
      fonts.enableDefaultPackages = false;
      fonts.packages = with pkgs; [
        dejavu_fonts
        freefont_ttf
        gyre-fonts
        liberation_ttf
        unifont
        noto-fonts-color-emoji
      ];
    }

    (lib.optionalAttrs (options ? isoImage) {
      system.installer.channel.enable = false;
      # try to sync some package choice with the installed system to avoid double load on image
      boot.kernelPackages = pkgs.linuxPackages_latest;
      nix.package = pkgs.nixVersions.latest;
      boot.supportedFilesystems.zfs = lib.mkForce false;
    })
  ];
}
