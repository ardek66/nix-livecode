with builtins;

final: prev:
let
  quarks = (foldl' (acc: quark:
    acc // {
      ${quark.name} =
        final.supercolliderPlugins.buildQuark {
          inherit (quark) name;

          dependencies =
            map (pkg: final.supercolliderPlugins.${pkg})
              quark.dependencies or [];

          src = prev.fetchgit {
            inherit (quark.src) url rev sha256;
          };
        };
    }) {} (fromJSON (readFile ./private/quarks.json)));
in {
  supercolliderPlugins = prev.supercolliderPlugins // {
    buildQuark = { name, src, dependencies ? [], external ? [] }:
      let target = "share/SuperCollider/Extensions";
      in prev.stdenv.mkDerivation {
        inherit name src;

        buildInputs = dependencies;
        propagatedBuildInputs = external;
        
        installPhase =
          ''
          mkdir -p $out/${target}/${name}
          cp -ar * $out/${target}/${name}
          for dep in $buildInputs; do
              ln -s $dep/${target}/* $out/${target}
          done
          '';
      };
  }
  // quarks;
}
