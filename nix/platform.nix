{ inputs, ... }:

{
  perSystem = { system, lib, ... }:

    let
      inherit (inputs.gitignore.lib) gitignoreSource;
      overlays = [ (import inputs.rust-overlay) ];
      nixpkgs = inputs.nixpkgs;
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
      LANG = "C.UTF-8";
      src = gitignoreSource ./../platform_umbrella;
      version = "0.11.0";
      beam = pkgs.beam;

      beamPackages = beam.packagesWith beam.interpreters.erlang_26;

      # all elixir and erlange packages
      erlang = beamPackages.erlang;
      elixir = beamPackages.elixir_1_15;
      hex = beamPackages.hex;

      rustToolChain = pkgs.rust-bin.nightly.latest.default;
      pkg-config = pkgs.pkg-config;
      gcc = pkgs.gcc;
      openssl = pkgs.openssl;

      nodejs = pkgs.nodejs;

      npmlock2nix = pkgs.callPackages inputs.npmlock2nix { };

      mixTestFodDeps = beamPackages.fetchMixDeps {
        pname = "mix-deps-platform-test";
        inherit src version LANG;
        mixEnv = "test";
        #sha256 = lib.fakeSha256;
        sha256 = "sha256-gz2ZiqEt92026oZLbV12tfOCw759f8jO5lG/jZCynyc=";
      };

      # mix fixed output derivation dependencies
      # Nix usually doesn't allow any step to reach the internet since that can
      # introduce some changes in output. These derivations have to have the
      # output hash fixed which allows them network access. So we say this step
      # should result in X.
      # TODO(jdt): somehow use the hashes from mix.lock instead
      mixFodDeps = beamPackages.fetchMixDeps {
        pname = "mix-deps-platform";
        inherit src version LANG;
        #sha256 = lib.fakeSha256;
        sha256 = "sha256-BBlkG6sgB0GbkE5GNW8RXZ+RSsYUfkgluduZdcEiRto=";
      };

      control-server = pkgs.callPackage ./platform_release.nix {
        inherit version src mixFodDeps pkgs nixpkgs;
        inherit erlang elixir hex;
        inherit npmlock2nix nodejs;
        inherit rustToolChain pkg-config gcc openssl;

        pname = "control_server";
        mixEnv = "prod";
      };

      kube-bootstrap = beamPackages.mixRelease
        {
          inherit src version mixFodDeps;
          inherit erlang elixir hex;
          MIX_ENV = "prod";
          LANG = "C.UTF-8";
          pname = "kube_bootstrap";

          nativeBuildInputs = [ gcc rustToolChain pkg-config ];
          buildInputs = [ openssl ];
          installPhase = ''
            export APP_VERSION="${version}"
            export APP_NAME="batteries_included"
            export RELEASE="kube_bootstrap"
            mix do compile --force, \
              release --no-deps-check --overwrite --path "$out" kube_bootstrap
          '';

        };

      home-base = pkgs.callPackage ./platform_release.nix {
        inherit version src mixFodDeps pkgs nixpkgs;
        inherit erlang elixir hex;
        inherit npmlock2nix nodejs;
        inherit rustToolChain pkg-config gcc openssl;

        pname = "home_base";
        mixEnv = "prod";
      };

      credo = pkgs.callPackage ./mix-command.nix {
        inherit version src pkgs;
        inherit erlang elixir hex;
        inherit rustToolChain pkg-config gcc openssl;

        pname = "platform";
        mixEnv = "test";
        mixFodDeps = mixTestFodDeps;
        command = "credo";
      };

      dialyzer = pkgs.callPackage ./mix-command.nix {
        inherit version src pkgs;
        inherit erlang elixir hex;
        inherit rustToolChain pkg-config gcc openssl;

        pname = "platform";
        mixEnv = "test";
        mixFodDeps = mixTestFodDeps;
        command = "dialyzer";
      };

      format = pkgs.callPackage ./mix-command.nix {
        inherit version src pkgs;
        inherit erlang elixir hex;
        inherit rustToolChain pkg-config gcc openssl;

        pname = "platform";
        mixEnv = "test";
        mixFodDeps = mixTestFodDeps;
        command = "format --check-formatted";
      };

    in
    {
      packages = {
        inherit home-base control-server kube-bootstrap;
      };
      checks = {
        inherit credo dialyzer format;
      };
    };
}
