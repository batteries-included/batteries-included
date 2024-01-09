{ inputs, ... }:

{

  perSystem = { system, config, lib, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ (import inputs.rust-overlay) ];
        config.allowUnfree = true;
      };

      beam = pkgs.beam;
      beamPackages = beam.packagesWith beam.interpreters.erlang_26;
      erlang = beamPackages.erlang;
      rebar = beamPackages.rebar;
      rebar3 = beamPackages.rebar3;

      # elixir and elixir-ls are using the same version
      elixir = beamPackages.elixir_1_15;
      elixir-ls = beamPackages.elixir-ls.override { elixir = elixir; };

      elixirNativeTools = with pkgs; [
        erlang
        elixir

        rebar
        rebar3
        hex
        elixir-ls
        sqlite

        postgresql

        bind

        graphite-cli
      ];

      rustNativeBuildTools = with pkgs; [
        rust-bin.nightly.latest.complete
        pkg-config
        cargo-flamegraph
        postgresql
      ];


      linuxOnlyTools = with pkgs; [
        # Track when files change for css updates
        inotify-tools
      ];

      integrationTestingTools = with pkgs; [
        # Yes the whole fucking world
        # just for integration tests.
        chromedriver
        chromium
        selenium-server-standalone
      ];

      frameworks = pkgs.darwin.apple_sdk.frameworks;

      darwinOnlyTools = [
        frameworks.Security
        frameworks.CoreServices
        frameworks.CoreFoundation
        frameworks.Foundation
        pkgs.qemu
      ];


      nativeBuildInputs = with pkgs; [
        # node is needed, because
        # javascript won for better or worse
        nodejs

        # Command line tools
        cachix
        fswatch
        jq
        k9s
        kind
        kubectl
        kubernetes-helm
        podman
        terraform

        skopeo # Use for pushing docker
        wireguard-tools

        ansible
        (awscli2.override { python3 = python310; })
        ssm-session-manager-plugin
      ]
      ++ elixirNativeTools
      ++ rustNativeBuildTools
      ++ lib.optionals pkgs.stdenv.isDarwin darwinOnlyTools
      ++ lib.optionals pkgs.stdenv.isLinux linuxOnlyTools
      ++ lib.optionals (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.chromium) integrationTestingTools
      ++ [ config.treefmt.build.wrapper ];


      buildInputs = with pkgs; [
        openssl
        glibcLocales
      ];

      shellHook = ''
        # NOTE(jdt): try very hard not to run mix commands here.
        # they take a bit to start and execute even if they don't do anything
        [[ -z ''${TRACE:-""} ]] || set -x

        # go to the top level.
        pushd "$FLAKE_ROOT" &> /dev/null

        # this allows mix to work on the local directory
        export MIX_HOME=$PWD/.nix-mix
        mkdir -p $MIX_HOME

        export HEX_HOME=$PWD/.nix-hex
        mkdir -p $HEX_HOME

        export ELIXIR_MAKE_CACHE_DIR=$PWD/.nix-elixir.cache
        mkdir -p $ELIXIR_MAKE_CACHE_DIR

        export PATH=$MIX_HOME/bin:$PATH
        export PATH=$HEX_HOME/bin:$PATH

        pushd platform_umbrella &> /dev/null
        find $MIX_HOME -type f -name 'rebar3' -executable -print0 | grep -qz . \
            || mix local.rebar --if-missing rebar3 ${rebar3}/bin/rebar3
        find $MIX_HOME -type f -name 'hex.app' -print0 | grep -qz . \
            || mix local.hex --force --if-missing
        popd &> /dev/null

        # This keeps cargo self contained in this dir
        export CARGO_HOME=$PWD/.nix-cargo
        mkdir -p $CARGO_HOME
        export PATH=$CARGO_HOME/bin:$PATH

        popd &> /dev/null
      '';

    in
    {
      devShells.default = pkgs.mkShell {
        inherit nativeBuildInputs buildInputs shellHook;
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
        LC_CTYPE = "en_US.UTF-8";
        RUST_BACKTRACE = 1;
        ERL_AFLAGS = "-kernel shell_history enabled";

        inputsFrom = [ config.mission-control.devShell config.flake-root.devShell ];
      };
    };
}
