with builtins;

final: prev:
let
  quarks = (foldl' (acc: quark:
    acc // {
      ${quark.name} =
        final.supercolliderPlugins.buildQuark {
          inherit (quark) name;
          dependencies = quark.dependencies or [];

          src = prev.fetchgit {
            inherit (quark.src) url rev sha256;
          };
        };
    }) {} (fromJSON (readFile ./private/quarks.json)));
in {
  supercolliderPlugins = prev.supercolliderPlugins // {
    buildQuark = { name, src, dependencies ? [] }:
      let target = "share/SuperCollider/Extensions";
      in prev.stdenv.mkDerivation {
        inherit name src;

        buildInputs =
          map (pkg: final.supercolliderPlugins.${pkg})
            dependencies;

        installPhase =
          ''
          mkdir -p $out/${target}/${name}
          cp -r * $out/${target}/${name}
          for dep in $buildInputs; do
              ln -s $dep/${target}/* $out/${target}
          done
          '';
      };
  }
  // quarks;
}
