{
  nix.settings = {
    auto-allocate-uids = true;
    experimental-features = [
      "auto-allocate-uids"
      "cgroups"
    ];
    extra-system-features = [
      "uid-range"
      # VM <-> container networking. Exposes /dev/net to the sandbox, which
      # weakens sandbox isolation.
      "devnet"
    ];
    extra-sandbox-paths = [ "/dev/net" ];
  };
}
