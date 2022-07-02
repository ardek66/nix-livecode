{
  description = "Live algorave setup";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };
  
  outputs = { self, nixpkgs, flake-utils }: {
    overlays.default = import ./overlay.nix;
  } // flake-utils.lib.eachDefaultSystem(system:
    let
      pkgs = import nixpkgs {
        overlays = [ self.overlays.default ];
        inherit system;
      }; in
    rec {
      packages = flake-utils.lib.flattenTree {
        supercollider-extra =
          pkgs.supercollider-with-plugins.override {
            plugins = with pkgs.supercolliderPlugins; [ sc3-plugins API SuperDirt ];
          };

        ghc-with-tidal =
          pkgs.haskellPackages.ghcWithPackages(p: [ p.tidal ]);
      };

      devShells.default = pkgs.mkShell {
        buildInputs = with packages;
          [ pkgs.nix-prefetch-git supercollider-extra ghc-with-tidal ];
      };
    });
}
