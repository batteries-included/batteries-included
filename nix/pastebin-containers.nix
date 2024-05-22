{ self, ... }:
{
  perSystem =
    { self', pkgs, ... }:
    let
      safeRev = self.shortRev or self.dirtyShortRev;
      version = "0.12.3";
      taggedVersion = "${version}-${safeRev}";
      # These are the same contents in all our containers
      contents = [
        pkgs.bash
        pkgs.coreutils
        pkgs.bind
        pkgs.cacert
        pkgs.dockerTools.caCertificates
      ];
      Entrypoint =
        if pkgs.stdenv.isDarwin then
          [ ]
        else
          [
            "${pkgs.tini}/bin/tini"
            "--"
          ];

      inherit (self'.packages) pastebin;
      inherit (self'.packages) pastebin-static;
    in
    {
      packages.pastebin-container = pkgs.dockerTools.buildLayeredImage {
        name = "pastebin";
        tag = taggedVersion;
        contents = [
          pastebin
          pastebin-static
        ] ++ contents;
        config = {
          ExposedPorts = {
            "8080/tcp" = { };
          };
          # Put the working dir in the pack
          WorkingDir = "${pastebin-static}/";
          Cmd = [
            "${pastebin}/bin/pastebin"
            "."
          ];
          inherit Entrypoint;
        };
      };
    };
}
