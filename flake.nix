{
  description = "Live algorave setup";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };
  
  outputs = { self, nixpkgs, flake-utils }: {
    overlay = import ./overlay.nix;
  } // flake-utils.lib.eachDefaultSystem(system:
    let
      pkgs = import nixpkgs {
        overlays = [ self.overlay ];
        inherit system;
      };
    in {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs;
          [ nix-prefetch-git supercollider-extra ghc-with-tidal ];
      };
    });
}
