{ inputs, ... }:

{

  perSystem = { system, nixpkgs, rust-overlay, ... }:
    let
      overlays = [ (import inputs.rust-overlay) ];
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };


    in
    {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          elixir
          mix2nix

          # for rust
          rust-bin.stable.latest.complete
          pkg-config
          cargo-flamegraph
          postgresql
          sqlite

          # For static site generation
          zola

          # Command line tools
          jq
          k9s
          kind
          kubectl

          # Use for pushing docker
          skopeo

          terraform
        ]
        ++ lib.optionals pkgs.stdenv.isDarwin [ ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          inotify-tools
          nodejs
        ];

        buildInputs = with pkgs; [
          openssl_1_1
        ];
        RUST_BACKTRACE = 1;

      };
    };
}
