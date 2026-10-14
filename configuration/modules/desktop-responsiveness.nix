{ lib, ... }:
{
  systemd.services.nix-daemon.serviceConfig = {
    CPUSchedulingPolicy = lib.mkForce "idle";
    IOSchedulingClass = lib.mkForce "idle";
    IOSchedulingPriority = lib.mkForce 7;
    CPUWeight = 20;
    IOWeight = 20;
    MemoryHigh = "70%";
    MemoryMax = "85%";
  };

  nix.settings.use-cgroups = true;
  nix.settings.experimental-features = [ "cgroups" ];
  services.earlyoom.enable = true;
}
