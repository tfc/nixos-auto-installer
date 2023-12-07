{ pkgs, config, lib, ... }:
let
  cfg = config.customization.gdm-logo;
  overlayFunction = final: prev: {
    gnome = prev.gnome.overrideScope' (finalGnome: prevGnome: {
      gdm =
        let
          logo-override = builtins.toFile "logo-override" ''
            [org.gnome.login-screen]
            logo='${cfg.logoPath}'
          '';
        in
        prevGnome.gdm.overrideAttrs (old: {
          preInstall = ''
            install -D ${logo-override} \
              $out/share/glib-2.0/schemas/org.gnome.login-screen.gschema.override
          '';
        });
    });
  };
in
{
  options.customization.gdm-logo = {
    enable = lib.mkEnableOption "GDM icon customization";
    logoPath = lib.mkOption {
      type = lib.types.path;
      default = ./artwork/logo-horizontal-white.png;
      description = "Path to the logo file";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ overlayFunction ];
  };
}
