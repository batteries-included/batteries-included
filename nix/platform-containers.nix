{ self, ... }:
{
  perSystem =
    { self', pkgs, ... }:
    let
      safeRev = self.shortRev or self.dirtyShortRev;
      version = "0.12.5";
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

      # UTF-8 is the only encoding we support.
      # Tell that to elixir.
      Env = [
        "LC_ALL=en_US.UTF-8"
        "LANG=en_US.UTF-8"
        "LC_CTYPE=en_US.UTF-8"
      ];
    in
    {
      packages = {
        kube-bootstrap-container = pkgs.dockerTools.buildLayeredImage {
          name = "kube-bootstrap";
          tag = taggedVersion;
          contents = [ self'.packages.kube-bootstrap ] ++ additionalContents;
          config = {
            inherit Entrypoint Env;
            Cmd = [ "bootstrap" ];
          };
        };

        home-base-container = pkgs.dockerTools.buildLayeredImage {
          name = "home-base";
          tag = taggedVersion;
          contents = [ self'.packages.home-base ] ++ additionalContents;
          config = {
            inherit Entrypoint Env;
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
            inherit Entrypoint Env;
            Cmd = [
              "control_server"
              "start"
            ];
          };
        };
      };
    };
}
