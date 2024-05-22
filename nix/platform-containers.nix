{ self, ... }:
{
  perSystem =
    { self', pkgs, ... }:
    let
      safeRev = self.shortRev or self.dirtyShortRev;
      version = "0.12.3";
      taggedVersion = "${version}-${safeRev}";
      additionalContents = [
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
    in
    {
      packages = {
        kube-bootstrap-container = pkgs.dockerTools.buildLayeredImage {
          name = "kube-bootstrap";
          tag = taggedVersion;
          contents = [ self'.packages.kube-bootstrap ] ++ additionalContents;
          config = {
            inherit Entrypoint;
            Cmd = [ "bootstrap" ];
          };
        };

        home-base-container = pkgs.dockerTools.buildLayeredImage {
          name = "home-base";
          tag = taggedVersion;
          contents = [ self'.packages.home-base ] ++ additionalContents;
          config = {
            inherit Entrypoint;
            Cmd = [
              "home_base"
              "start"
            ];
          };
        };

        control-server-container = pkgs.dockerTools.buildLayeredImage {
          name = "control-server";
          tag = taggedVersion;
          contents = [ self'.packages.control-server ] ++ additionalContents;
          config = {
            inherit Entrypoint;
            Cmd = [
              "control_server"
              "start"
            ];
          };
        };
      };
    };
}
