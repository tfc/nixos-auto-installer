# Settings for trainings in Germany. Remove the import from configuration.nix
# for international trainings.
{ lib, ... }:

{
  # Most laptops there have German keyboards. The system layout applies to GDM
  # and (via useXkbConfig) the console, the dconf default to GNOME sessions.
  services.xserver.xkb.layout = "de";
  console.useXkbConfig = true;
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/input-sources".sources = [
        (lib.gvariant.mkTuple [
          "xkb"
          "de"
        ])
        (lib.gvariant.mkTuple [
          "xkb"
          "us"
        ])
      ];
    }
  ];
}
