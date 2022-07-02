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
        nix-prefetch-git = pkgs.nix-prefetch-git;

        nixQuarks =
          pkgs.supercolliderPlugins.buildQuark {
            name = "nixToQuark";
            src = ./private;
            dependencies = [ pkgs.supercolliderPlugins.API ];
            external = [ packages.nix-prefetch-git ];
        };

        supercollider-devel =
          pkgs.supercollider-with-plugins.override {
            plugins = [ packages.nixQuarks ];
          };

        supercollider-tidal =
          pkgs.supercollider-with-plugins.override {
            plugins = with pkgs.supercolliderPlugins;
              [ sc3-plugins SuperDirt ];
          };

        ghc-with-tidal =
          pkgs.haskellPackages.ghcWithPackages(p: [ p.tidal ]);
      };

      devShells.devel = pkgs.mkShell {
        buildInputs = with packages; [ nix-prefetch-git supercollider-devel ];
      };

      devShells.default = pkgs.mkShell {
        buildInputs = with packages;
          [ supercollider-tidal ghc-with-tidal ];
      };
    });
}
