with builtins;

final: prev:
let
  quarks = (foldl' (acc: quark:
    acc // {
      ${quark.name} =
        final.supercolliderPlugins.buildQuark {
          inherit (quark) name;

          propagatedBuildInputs =
            map (pkg: final.supercolliderPlugins.${pkg})
              quark.dependencies or [];

          src = prev.fetchgit {
            inherit (quark.src) url rev sha256;
          };
        };
    }) {} (fromJSON (readFile ./private/quarks.json)));
in {
  supercollider =
    prev.supercollider.overrideAttrs (old: {
      patches = old.patches ++ [ ./supercollider.patch ];
    });

  supercollider-with-plugins = f:
    let
      plugins = f final.supercolliderPlugins;
      paths =
        prev.lib.concatMapStringsSep "\n" (pkg:
          if pathExists "${pkg}/nix-support" then
            readFile "${pkg}/nix-support/include-paths"
          else
            " - ${pkg}") plugins;
    in prev.symlinkJoin {
      name = "supercollider-with-plugins";

      paths = [ final.supercollider
                (prev.writeTextDir "share/SuperCollider/sclang_conf.yaml"
                  ''
                    includePaths:
                    ${paths}
                    excludePaths: []
                    postInlinewarnings: false
                    '')];
      
      nativeBuildInputs = [ prev.makeWrapper ];
      
      postBuild = ''
                  for exe in $out/bin/*; do
                      wrapProgram $exe \
                      --set SC_PLUGIN_DIR "$out/lib/SuperCollider/plugins" \
                      --set SC_DATA_DIR   "$out/share/SuperCollider"
                  done
                  '';
    };
  
  supercolliderPlugins = prev.supercolliderPlugins // {
    buildQuark = { name, src, propagatedBuildInputs ? [], buildInputs ? [] }:
      prev.stdenv.mkDerivation {
        inherit name src buildInputs propagatedBuildInputs;
        
        installPhase =
          ''
          mkdir -p $out/share/SuperCollider/Extensions/${name}
          cp -ar * $out/share/SuperCollider/Extensions/${name}

          mkdir -p $out/nix-support
          echo " - $out/share/SuperCollider/Extensions" > $out/nix-support/include-paths

          for p in $propagatedBuildInputs
          do
            echo " - $p/share/SuperCollider/Extensions" >> $out/nix-support/include-paths
          done
          '';
      };

    nixQuarks =
      final.supercolliderPlugins.buildQuark {
            name = "nixToQuark";
            src = ./private;
            buildInputs = [ prev.nix-prefetch-git ];
            propagatedBuildInputs = [ final.supercolliderPlugins.API ];
        };

  }
  // quarks;
}
