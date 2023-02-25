{ inputs, ... }:

{
  perSystem = { system, ... }:

    let
      overlays = [ (import inputs.rust-overlay) ];
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
      src = ../platform_umbrella;

      pname = "control_server";
      version = "0.5.0";
      nodejs = pkgs.nodejs;
      npmlock2nix = pkgs.callPackages inputs.npmlock2nix { };
      control-server = pkgs.callPackage ./platform_release.nix {
        inherit pname version npmlock2nix src;
      };
    in
    {
      packages.control-server = control-server;
    };
}
