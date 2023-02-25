{
  description = "The entire Batteries Included world";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
        flake-utils.follows = "flake-utils";
      };
    };
    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };
    npmlock2nix = {
      url = "github:nix-community/npmlock2nix";
      flake = false;
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs = { nixpkgs-lib.follows = "nixpkgs"; };
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs = { nixpkgs.follows = "nixpkgs"; };
    };
  };

  outputs = inputs@{ flake-utils, treefmt-nix, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = flake-utils.lib.defaultSystems;
      imports = [
        treefmt-nix.flakeModule
        ./nix/shell.nix
        ./nix/cli.nix
        ./nix/pastebin.nix
        ./nix/control.nix
      ];
      perSystem = { ... }:
        {

          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixpkgs-fmt.enable = true;
            programs.rustfmt.enable = true;
            programs.black.enable = true;
            programs.prettier.enable = true;
          };
        };
    };

}
