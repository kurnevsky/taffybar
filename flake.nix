{
  inputs = {
    flake-utils.url = github:numtide/flake-utils;
    git-ignore-nix.url = github:IvanMalison/gitignore.nix/master;
    gtk-sni-tray.url = github:taffybar/gtk-sni-tray/master;
  };
  outputs = { self, flake-utils, nixpkgs, git-ignore-nix, gtk-sni-tray }:
  let
    overlay = final: prev: {
      haskellPackages = prev.haskellPackages.override (old: {
        overrides = prev.lib.composeExtensions (old.overrides or (_: _: {}))
        (hself: hsuper: {
          taffybar =
            hself.callCabal2nix "taffybar"
            (git-ignore-nix.gitIgnoreSource ./.)
            { inherit (final) gtk3;  };
          dyre = prev.haskell.lib.dontCheck (hself.callHackageDirect {
            pkg = "dyre";
            ver = "0.9.1";
            sha256 = "sha256-3ClPPbNm5wQI+QHaR0Rtiye2taSTF3IlWgfanud6wLg=";
          } { });
        });
      });
    };
    overlays = gtk-sni-tray.overlays ++ [ overlay ];
  in flake-utils.lib.eachDefaultSystem (system:
  let pkgs = import nixpkgs { inherit system overlays; config.allowBroken = true; };
  in
  rec {
    devShell = pkgs.haskellPackages.shellFor {
      packages = p: [ p.taffybar ];
    };
    defaultPackage = pkgs.haskellPackages.taffybar;
  }) // { inherit overlay overlays; } ;
}
