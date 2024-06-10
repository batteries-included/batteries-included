{ inputs, self, ... }:
{
  perSystem =
    { system, ... }:
    let
      inherit (inputs.gitignore.lib) gitignoreSource;

      inherit (inputs.gomod2nix.legacyPackages.${system}) buildGoApplication;
      src = gitignoreSource ../bi;
      pwd = ../bi;
      pname = "bi";
      modules = ../bi/gomod2nix.toml;
      safeRev = self.shortRev or self.dirtyShortRev;
      version = "0.12.4";
      taggedVersion = "${version}-${safeRev}";
    in
    {
      checks.bi = buildGoApplication {
        inherit
          src
          pwd
          pname
          version
          modules
          ;
        doCheck = true;
      };

      packages.bi = buildGoApplication {
        inherit
          src
          pwd
          pname
          version
          modules
          ;
        doCheck = false;

        CGO_ENABLED = 0;
        flags = [ "-trimpath" ];
        tags = [
          "netgo"
          "osusergo"
        ];
        ldflags = [ "-X bi/pkg.Version=${taggedVersion}" ];
      };
    };
}
