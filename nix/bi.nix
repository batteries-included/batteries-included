{ inputs, ... }:

{
  perSystem = { system, ... }:
    let
      inherit (inputs.gitignore.lib) gitignoreSource;

      inherit (inputs.gomod2nix.legacyPackages.${system}) buildGoApplication;
      src = gitignoreSource ../bi;
      pwd = ../bi;
      pname = "bi";
      version = "0.1";
      modules = ../bi/gomod2nix.toml;
    in
    {

      checks.bi = buildGoApplication {
        inherit src pwd pname version modules;
        doCheck = true;
      };

      packages.bi = buildGoApplication {
        inherit src pwd pname version modules;
        doCheck = false;
      };
    };
}
