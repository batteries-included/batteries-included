{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    elixir_1_14
    nodejs-19_x
    inotify-tools
    openssl_1_1
    pkg-config

    kind
    kubectl

    clippy
    rustc
    cargo
    rustfmt
    rust-analyzer
    bashInteractive
  ];

  RUST_BACKTRACE = 1;
}
