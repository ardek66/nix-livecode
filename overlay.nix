with builtins;

final: prev:
let
  json = fromJSON (readFile ./private/quarks.json);
  quarks = (foldl' (acc: quark:
    acc // {
      ${quark.name} = prev.stdenv.mkDerivation {
        name = quark.name;
        version = quark.version;
        author = quark.author;

        buildInputs = [ prev.supercollider ];
        
        src = prev.fetchgit {
          url = "${quark.src.url}";
          sha256 = "${quark.src.sha256}";
        };

        installPhase = ''
                       mkdir -p $out/share/SuperCollider/Extensions/${quark.name}
                       cp -r * $out/share/SuperCollider/Extensions/${quark.name}
                       '';
      };
    }) {} json.quarks);
in {
  supercolliderPlugins = prev.supercolliderPlugins // quarks;
  
  supercollider-extra =
    prev.supercollider-with-plugins.override {
      plugins = with final.supercolliderPlugins; [ sc3-plugins SuperDirt Vowel ];
    };

  ghc-with-tidal =
    prev.haskellPackages.ghcWithPackages(p: [ p.tidal ]);
}
