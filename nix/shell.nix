{ inputs, ... }:

{

  perSystem = { system, config, lib, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.gomod2nix.overlays.default
          (import inputs.rust-overlay)
        ];
        config.allowUnfree = true;
      };

      beam = pkgs.beam;
      beamPackages = beam.packagesWith beam.interpreters.erlang_26;
      erlang = beamPackages.erlang;
      rebar = beamPackages.rebar;
      rebar3 = beamPackages.rebar3;

      # elixir and elixir-ls are using the same version
      elixir = beamPackages.elixir_1_16;
      elixir-ls = (beamPackages.elixir-ls.override { inherit elixir; }).overrideAttrs (_old: {
        buildPhase =
          ''
            runHook preBuild
            mix do compile --no-deps-check, elixir_ls.release2
            runHook postBuild
          '';
      });

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
      ];

      rustNativeBuildTools = with pkgs; [
        rust-bin.nightly.latest.complete
        pkg-config
        cargo-flamegraph
        postgresql
      ];

      goNativeBuildTools = with pkgs; [
        go
        gotools
        gopls
        go-outline
        gopkgs
        gocode-gomod
        godef
        golint
        gomod2nix
        cobra-cli
      ];


      linuxOnlyTools = with pkgs; [
        # Track when files change for css updates
        inotify-tools
      ];

      # Yes the whole fucking world
      # just for integration tests.
      integrationTestingTools = with pkgs; [
        chromedriver
        selenium-server-standalone
      ]
      ++ lib.optionals (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.chromium) [ chromium ];

      frameworks = pkgs.darwin.apple_sdk.frameworks;

      darwinOnlyTools = [
        frameworks.Security
        frameworks.CoreServices
        frameworks.CoreFoundation
        frameworks.Foundation
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
        flock
        pulumi-bin

        skopeo # Use for pushing docker
        wireguard-tools
        age # secure out of band communications
        nixpkgs-fmt

        awscli2
        ssm-session-manager-plugin
      ]
      ++ elixirNativeTools
      ++ rustNativeBuildTools
      ++ goNativeBuildTools
      ++ lib.optionals pkgs.stdenv.isDarwin darwinOnlyTools
      ++ lib.optionals pkgs.stdenv.isLinux linuxOnlyTools
      ++ integrationTestingTools
      ++ [ config.treefmt.build.wrapper ]
      ++ [ config.packages.bi ];


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

        export GOPATH=$PWD/.nix-go
        mkdir -p $GOPATH

        # place to put lock files for nix shell scripts
        mkdir -p .nix-lock

        export PATH=$MIX_HOME/bin:$PATH
        export PATH=$HEX_HOME/bin:$PATH

        pushd platform_umbrella &> /dev/null
        find $MIX_HOME -type f -name 'rebar3' -executable -print0 | grep -qz . \
            || mix local.rebar --if-missing rebar3 ${rebar3}/bin/rebar3


        # Install hex if it's not there
        # However we need to compile the hex app to not run into:
        # https://github.com/erlang/otp/issues/8238
        find $MIX_HOME -type f -name 'hex.app' -print0 | grep -qz . \
            || mix archive.install github hexpm/hex branch latest --force
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
