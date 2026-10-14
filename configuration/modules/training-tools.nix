{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    tmux
    unzip

    nix-output-monitor
    nix-tree
    flake-du
    gcan

    # Language server and formatter picked up by the nix-ide extension
    nixd
    nixfmt
  ];

  programs.direnv.enable = true;

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      jnoortheen.nix-ide
      mkhl.direnv
    ];
  };
}
