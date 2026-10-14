{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.customization;

  logo = pkgs.runCommand "logo.png" { HOME = "/build"; } ''
    ${lib.getExe pkgs.inkscape} -w 256 -o "$out" ${cfg.plymouth-logo.logoPath}
  '';
  customBreeze = pkgs.kdePackages.breeze-plymouth.override {
    logoFile = logo;
    logoName = "Nixcademy";
    osName = "NixOS";
    osVersion = config.system.nixos.release;
  };

  # Render the tiling wallpaper SVG to a 4K PNG, recoloring its .bg (background)
  # and .logo (logo) fills to the requested HTML color codes. Both placeholder
  # fills appear exactly once in the SVG's <style> block, so the substitution is
  # unambiguous.
  mkWallpaper =
    name:
    { backgroundColor, logoColor }:
    pkgs.runCommand name
      {
        HOME = "/build";
        nativeBuildInputs = [ pkgs.inkscape ];
      }
      ''
        cp ${cfg.gnome-background.tilingSvg} colored.svg
        # Anchor each substitution on its class selector. Replacing the bare
        # 'fill:#000000' would also hit a background recolored to #000000 (the
        # dark scheme), collapsing background and logo to the same grey.
        substituteInPlace colored.svg \
          --replace-fail '.bg   { fill:#ffffff }' '.bg   { fill:${backgroundColor} }' \
          --replace-fail '.logo { fill:#000000 }' '.logo { fill:${logoColor} }'
        inkscape -w 3840 -h 2160 -o "$out" colored.svg
      '';

  lightWallpaper = mkWallpaper "wallpaper-nixcademy-light.png" {
    inherit (cfg.gnome-background.light) backgroundColor logoColor;
  };
  darkWallpaper = mkWallpaper "wallpaper-nixcademy-dark.png" {
    inherit (cfg.gnome-background.dark) backgroundColor logoColor;
  };

  reset-background = pkgs.writeShellApplication {
    name = "gnome-reset-background";
    runtimeInputs = [ pkgs.glib ];
    text = ''
      gsettings reset org.gnome.desktop.background picture-uri
      gsettings reset org.gnome.desktop.background picture-uri-dark
    '';
  };
in
{
  options.customization = {
    gdm-logo = {
      enable = lib.mkEnableOption "GDM icon customization" // {
        default = true;
      };
      logoPath = lib.mkOption {
        type = lib.types.path;
        default = ./artwork/logo-horizontal-white.png;
        description = "Path to the logo file";
      };
    };
    gnome-background = {
      enable = lib.mkEnableOption "GNOME custom background setter" // {
        default = true;
      };
      tilingSvg = lib.mkOption {
        type = lib.types.path;
        default = ./artwork/logos/tiling-wallpaper.svg;
        description = ''
          Path to the tiling wallpaper SVG. Its <style> block must expose a
          .bg fill of #ffffff and a .logo fill of #000000, which get recolored
          to the light/dark color codes below when rendering the PNGs.
        '';
      };
      light = {
        backgroundColor = lib.mkOption {
          type = lib.types.str;
          default = "#f0f0f0";
          description = "HTML color code for the wallpaper background in the light color scheme";
        };
        logoColor = lib.mkOption {
          type = lib.types.str;
          default = "#999999";
          description = "HTML color code for the tiled logos in the light color scheme";
        };
      };
      dark = {
        backgroundColor = lib.mkOption {
          type = lib.types.str;
          default = "#000000";
          description = "HTML color code for the wallpaper background in the dark color scheme";
        };
        logoColor = lib.mkOption {
          type = lib.types.str;
          default = "#737373";
          description = "HTML color code for the tiled logos in the dark color scheme";
        };
      };
      resetUserBackground =
        lib.mkEnableOption (
          "resetting each user's GNOME background keys to the system default at session start, "
          + "so per-user dconf overrides do not shadow the system-provided wallpaper"
        )
        // {
          default = true;
        };
    };
    plymouth-logo = {
      enable = lib.mkEnableOption "Plymouth icon customization" // {
        default = true;
      };
      logoPath = lib.mkOption {
        type = lib.types.path;
        default = ./artwork/logo-horizontal-white.svg;
        description = "Path to the logo file (SVG)";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.gdm-logo.enable {
      programs.dconf.profiles.gdm.databases = [
        {
          settings."org/gnome/login-screen" = {
            logo = toString cfg.gdm-logo.logoPath;
          };
        }
      ];
    })
    (lib.mkIf cfg.gnome-background.enable {
      services.desktopManager.gnome.extraGSettingsOverrides = ''
        [org.gnome.desktop.background]
        picture-uri='file://${lightWallpaper}'
        picture-uri-dark='file://${darkWallpaper}'
      '';
    })
    (lib.mkIf (cfg.gnome-background.enable && cfg.gnome-background.resetUserBackground) {
      systemd.user.services.gnome-reset-background = {
        description = "Reset GNOME background to system default at login";
        unitConfig.ConditionEnvironment = "XDG_CURRENT_DESKTOP=GNOME";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe reset-background;
        };
      };
    })
    (lib.mkIf cfg.plymouth-logo.enable {
      boot.plymouth = {
        enable = true;
        inherit logo;
        themePackages = [ customBreeze ];
      };
    })
  ];
}
