{ inputs, ... }:

{
  perSystem = { system, lib, ... }:

    let
      overlays = [ (import inputs.rust-overlay) ];
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
      LANG = "C.UTF-8";
      src = ../platform_umbrella;
      version = "0.5.0";
      beam = pkgs.beam;

      beamPackages = beam.packagesWith beam.interpreters.erlang;

      # all elixir and erlange packages
      erlang = beamPackages.erlang;
      elixir = beamPackages.elixir;
      hex = beamPackages.hex;

      rustToolChain = pkgs.rust-bin.nightly.latest.default;
      pkg-config = pkgs.pkg-config;
      gcc = pkgs.gcc;
      libgcc = pkgs.libgcc;
      openssl_1_1 = pkgs.openssl_1_1;

      nodejs = pkgs.nodejs;

      npmlock2nix = pkgs.callPackages inputs.npmlock2nix { };

      mixTestFodDeps = beamPackages.fetchMixDeps {
        pname = "mix-deps-platform-test";
        inherit src version LANG;
        mixEnv = "test";
        sha256 = "sha256-ZOfxDq8VMc9pjTGg3j8s6ZwOfKjk0Scg7rVHV6D0uFA=";
        #sha256 = lib.fakeSha256;
      };

      mixFodDeps = beamPackages.fetchMixDeps {
        pname = "mix-deps-platform";
        inherit src version LANG;
        sha256 = "sha256-T33PaRWMUivQqzrper2M3uFpKOm3VXtrpLD9a9s1VTU=";
        #sha256 = lib.fakeSha256;
      };

      control-server = pkgs.callPackage ./platform_release.nix {
        inherit version src mixFodDeps pkgs;
        inherit erlang elixir hex;
        inherit npmlock2nix nodejs;
        inherit rustToolChain pkg-config gcc libgcc openssl_1_1;
        pname = "control_server";
        mixEnv = "prod";
      };
      home-base = pkgs.callPackage ./platform_release.nix {
        inherit version src mixFodDeps pkgs;
        inherit erlang elixir hex;
        inherit npmlock2nix nodejs;
        inherit rustToolChain pkg-config gcc libgcc openssl_1_1;

        pname = "home_base";
        mixEnv = "prod";
      };

      credo = pkgs.callPackage ./mix-command.nix {
        inherit version src pkgs;
        inherit erlang elixir hex;
        inherit rustToolChain pkg-config gcc libgcc openssl_1_1;

        pname = "platform";
        mixEnv = "test";
        mixFodDeps = mixTestFodDeps;
        command = "credo";
      };

      dialyzer = pkgs.callPackage ./mix-command.nix {
        inherit version src pkgs;
        inherit erlang elixir hex;
        inherit rustToolChain pkg-config gcc libgcc openssl_1_1;

        pname = "platform";
        mixEnv = "test";
        mixFodDeps = mixTestFodDeps;
        command = "dialyzer";
      };


      format = pkgs.callPackage ./mix-command.nix {
        inherit version src pkgs;
        inherit erlang elixir hex;
        inherit rustToolChain pkg-config gcc libgcc openssl_1_1;

        pname = "platform";
        mixEnv = "test";
        mixFodDeps = mixTestFodDeps;
        command = "format --check-formatted";
      };

    in
    {
      packages = {
        inherit home-base control-server;
      };
      checks = {
        inherit credo dialyzer format;
      };
    };
}
