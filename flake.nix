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
      inputs.nixpkgs.follows = "nixpkgs";
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
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # make nix emulate .gitignore via helpers
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # treefmt for nix. formats everything but elixir
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # provides custom CLI - e.g. bi commands
    mission-control = {
      url = "github:Platonic-Systems/mission-control";
    };
  };

  outputs = inputs@{ flake-utils, treefmt-nix, flake-root, flake-parts, mission-control, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = flake-utils.lib.defaultSystems;
      imports = [
        treefmt-nix.flakeModule
        flake-root.flakeModule
        mission-control.flakeModule
        ./nix/shell.nix
        ./nix/cli.nix
        ./nix/pastebin.nix
        ./nix/platform.nix
        ./nix/fmt.nix
        ./nix/mission-control.nix
      ];
    };
}
