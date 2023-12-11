{ inputs, ... }:

{
  perSystem = { system, ... }:
    let
      inherit (inputs.gitignore.lib) gitignoreSource;
      overlays = [ (import inputs.rust-overlay) ];
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      crane = inputs.crane;
      advisory-db = inputs.advisory-db;
      nodejs = pkgs.nodejs;
      npmlock2nix = pkgs.callPackages inputs.npmlock2nix { };

      pname = "pastebin";
      src = gitignoreSource ./../project_templates/pastebin;

      static = pkgs.callPackage ./pastebin_static.nix {
        inherit src pname npmlock2nix nodejs;
        name = "pastebin-static";
        version = "0.6.0";
      };

      crate-out = import ./rust_crate.nix {
        inherit pkgs crane advisory-db pname src;
        nativeBuildInputs = with pkgs; [ postgresql ];
        cargoExtraArgs = "--no-default-features";
      };
      docker-image = with crate-out; pkgs.dockerTools.buildImage {
        name = "elliottneilclark/${pname}";

        copyToRoot = pkgs.buildEnv {
          name = "static";
          pathsToLink = [ "/static" ];
          paths = [ static ];
        };

        config = {
          ExposedPorts = { "8080/tcp" = { }; };
          WorkingDir = "/";
          Cmd = [ "${packages.pastebin}/bin/${pname}" ];
        };
      };
      out =
        if (! pkgs.stdenv.isDarwin)
        then
          crate-out // (with crate-out; { packages = { pastebin = packages.pastebin; pastebin-docker = docker-image; }; })
        else
          crate-out;
    in
    out;
}
