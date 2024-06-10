{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      inherit (inputs.gitignore.lib) gitignoreSource;
      inherit (inputs.gomod2nix.legacyPackages.${system}) buildGoApplication;

      pname = "pastebin";
      pwd = ./../pastebin-go;
      src = gitignoreSource pwd;
      modules = pwd + "/gomod2nix.toml";
      version = "0.12.3";
    in
    {
      packages.pastebin = buildGoApplication {
        inherit
          pname
          src
          pwd
          modules
          version
          ;
      };
    };
}
