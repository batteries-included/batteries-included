{ npmlock2nix, src, pname, version, nodejs, name, stdenv, mixFodDeps, pkgs }:
let
  umbrella = stdenv.mkDerivation {
    inherit src pname version;
    name = "${pname}_umbrella";
    installPhase = '' 
        cp --no-preserve=mode -R "$src" "$out"
        cp --no-preserve=mode -R "${mixFodDeps}" "$out/deps"
    '';
  };
in
npmlock2nix.v2.build {
  inherit nodejs pname version name;
  installPhase = ''cp -r dist "$out"'';
  src = src + /apps/${pname}_web/assets/.;
  buildCommands = [
    ''
      export UMBRELLA_DIR="$TEMPDIR/umbrella"
      export ASSETS_DIR="$UMBRELLA_DIR/apps/${pname}_web/assets"
      cp --no-preserve=mode -R "${umbrella}" "$UMBRELLA_DIR"
      cp --no-preserve=mode -R node_modules "$ASSETS_DIR/node_modules"
      cd "$ASSETS_DIR"
      npm run css:deploy
      npm run js:deploy
    ''
  ];
}

