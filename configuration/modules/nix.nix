{ pkgs, ... }:

{
  nix = {
    package = pkgs.nixVersions.latest;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];

      connect-timeout = 5;
      fallback = true;

      trusted-users = [ "@wheel" ];
    };

    optimise.automatic = true;
  };
}
