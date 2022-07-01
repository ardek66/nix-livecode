with builtins;

final: prev:
let
  json = fromJSON (readFile ./private/quarks.json);
  quarks = (foldl' (acc: quark:
    acc // {
      ${quark.name} = prev.stdenv.mkDerivation rec {
        inherit (quark) name;
        
        src = prev.fetchgit {
          inherit (quark.src) url rev sha256; 
        };

        installPhase = ''
                       mkdir -p $out/share/SuperCollider/Extensions/${name}
                       cp -r * $out/share/SuperCollider/Extensions/${name}
                       '';
      };
    }) {} json.quarks);
in {
  supercolliderPlugins = prev.supercolliderPlugins // quarks;
  
  supercollider-extra =
    prev.supercollider-with-plugins.override {
      plugins = with final.supercolliderPlugins; [ sc3-plugins API SuperDirt Vowel ];
    };

  ghc-with-tidal =
    prev.haskellPackages.ghcWithPackages(p: [ p.tidal ]);
}
