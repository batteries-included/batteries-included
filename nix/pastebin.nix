{ inputs, self, ... }:

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
      safeRev = self.shortRev or self.dirtyShortRev;
      version = "0.12.0";
      taggedVersion = "0.12.0-${safeRev}";
      tini = pkgs.tini;


      staticSrc = gitignoreSource ./../project_templates/pastebin-go/assets;

      static = pkgs.callPackage ./pastebin_static.nix {
        inherit pname npmlock2nix nodejs version;
        name = "pastebin-static";
        src = staticSrc;
      };

      pastebin = buildGoApplication {
        inherit pname src pwd modules version;
      };

      pastebin-container = pkgs.dockerTools.buildLayeredImage {
        # TODO move this to batteries included when we have
        # a oci image host. For now this is on my personal account.
        name = "elliottneilclark/${pname}";

        tag = taggedVersion;

        config = {
          ExposedPorts = { "8080/tcp" = { }; };
          WorkingDir = "/";
          Entrypoint = [ "${tini}/bin/tini" "--" ];
          Cmd = [ "${pastebin}/bin/${pname}" "${static}/" ];
        };
      };
    in
    {
      packages = {
        inherit pastebin pastebin-container;
      };
    };
}
