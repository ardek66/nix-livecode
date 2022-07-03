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

  sclang-conf-yaml = ''
          includePaths:
            - $out/share/Quarks
          excludePaths:
              []
          postInlineWarnings: false
          excludeDefaultPaths: false\
        '';
in {
  supercollider =
    prev.supercollider.overrideAttrs (old: {
      patches = old.patches ++ [ ./supercollider.patch ];
    });
  
  supercolliderPlugins = prev.supercolliderPlugins // {
    buildQuark = { name, src, dependencies ? [], external ? [] }:
      prev.stdenv.mkDerivation {
        inherit name src;

        buildInputs = dependencies;
        propagatedBuildInputs = external;
        
        installPhase =
          ''
          mkdir -p $out/share/Quarks/${name}
          cp -ar * $out/share/Quarks/${name}

          for dep in $buildInputs
          do
            ln -s $dep/share/Quarks/* $out/share/Quarks
          done

          mkdir -p $out/share/SuperCollider
          echo "${sclang-conf-yaml}" >> $out/share/SuperCollider/sclang_conf.yaml
          '';
      };
  }
  // quarks;
}
