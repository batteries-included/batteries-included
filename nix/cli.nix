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
      src = gitignoreSource ./../cli;
      pname = "bcli";

      out = import ./rust_crate.nix {
        inherit pkgs crane advisory-db pname src;
        cargoExtraArgs = "--no-default-features";
      };
    in
    out;

}
