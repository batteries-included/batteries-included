{ npmlock2nix, src, pname, version, nodejs, name }:

npmlock2nix.v2.build {
  inherit src nodejs pname version name;
  installPhase = "cp -r dist $out";
  buildCommands = [ "npm run css:deploy" "npm run js:deploy" ];
}
