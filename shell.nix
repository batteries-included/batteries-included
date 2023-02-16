{ pkgs ? import <nixpkgs> {
  overlays = [
    (import (fetchTarball
      "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
  ];
} }:

let toolchain = pkgs.rust-bin.stable."1.67.1".complete;

in pkgs.mkShell {
  buildInputs = with pkgs; [
    elixir_1_14
    nodejs-19_x
    inotify-tools
    openssl_1_1
    pkg-config

    kind
    kubectl
    docker

    toolchain
    bashInteractive
  ];

  RUST_BACKTRACE = 1;
}
