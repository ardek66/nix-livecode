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
      prev.stdenv.mkDerivation rec {
        inherit name src;

        propagatedBuildInputs =
          map (pkg: final.supercolliderPlugins.${pkg})
            dependencies;

        installPhase =
          ''
          mkdir -p $out/share/SuperCollider/Extensions/${name}
          cp -r * $out/share/SuperCollider/Extensions/${name}
          '';
      };
  }
  // quarks;
}
