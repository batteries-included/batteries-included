{
  description = "The entire Batteries Included world";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # provides arch os pairs for flake-utils
    systems.url = "github:nix-systems/default";
    # provides additional utilities for working with flakes
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    # utilities for finding the flake root (e.g. where is flake.nix)
    # TODO(jdt): we should use this to inject FLAKE_ROOT into dev shell as it a supported mechanism
    flake-root.url = "github:srid/flake-root";
    # provides rust toolchain
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    # library for working w/ cargo
    crane = {
      url = "github:ipetkov/crane";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
        flake-utils.follows = "flake-utils";
      };
    };
    # vuln db for crates
    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };
    # converts NPM deps to work w/ Nix
    npmlock2nix = {
      url = "github:nix-community/npmlock2nix";
      flake = false;
    };

    # helper for modularizing flakes
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs = { nixpkgs-lib.follows = "nixpkgs"; };
    };
    # make nix emulate .gitignore via helpers
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # treefmt for nix. formats everything but elixir
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs = { nixpkgs.follows = "nixpkgs"; };
    };
  };

  outputs = inputs@{ flake-utils, treefmt-nix, flake-root, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = flake-utils.lib.defaultSystems;
      imports = [
        treefmt-nix.flakeModule
        flake-root.flakeModule
        ./nix/shell.nix
        ./nix/cli.nix
        ./nix/pastebin.nix
        ./nix/platform.nix
        ./nix/fmt.nix
      ];
    };
}
