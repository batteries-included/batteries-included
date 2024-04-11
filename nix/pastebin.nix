{ inputs, ... }:

{
  perSystem = { system, pkgs, ... }:
    let
      inherit (inputs.gitignore.lib) gitignoreSource;
      inherit (inputs.gomod2nix.legacyPackages.${system}) buildGoApplication;

      nodejs = pkgs.nodejs;
      npmlock2nix = pkgs.callPackages inputs.npmlock2nix { };

      pname = "pastebin";
      pwd = ./../project_templates/pastebin-go;
      src = gitignoreSource pwd;
      modules = pwd + "/gomod2nix.toml";

      staticSrc = gitignoreSource ./../project_templates/pastebin-go/assets;

      static = pkgs.callPackage ./pastebin_static.nix {
        inherit pname npmlock2nix nodejs;
        name = "pastebin-static";
        version = "0.8.0";
        src = staticSrc;
      };

      pastebin = buildGoApplication {
        inherit pname src pwd modules;
        version = "0.8.0";
      };

      docker-image = pkgs.dockerTools.buildImage {
        name = "elliottneilclark/${pname} ";

        copyToRoot = pkgs.buildEnv {
          name = "
          static ";
          pathsToLink = [ "/static" ];
          paths = [ static ];
        };

        config = {
          ExposedPorts = { " 8080/tcp " = { }; };
          WorkingDir = "/";
          Cmd = [ "${pastebin}/bin/${pname}" ];
        };
      };
    in
    {
      packages = {
        pastebin = pastebin;
        pastebin-docker = docker-image;
      };
    };
}
