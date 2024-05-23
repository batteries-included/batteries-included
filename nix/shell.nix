{ inputs, ... }:
{
  perSystem =
    {
      system,
      config,
      lib,
      ...
    }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.gomod2nix.overlays.default ];
        config.allowUnfree = true;
      };
      inherit (pkgs) beam;

      beamPackages = beam.packagesWith beam.interpreters.erlang_27;
      inherit (beamPackages) erlang;

      # These build and check.
      # However by the time that the devShell
      # is starting on a dev machine we believe
      # this is good.
      rebar = beamPackages.rebar.overrideAttrs (_old: {
        doCheck = false;
      });
      rebar3 = beamPackages.rebar3.overrideAttrs (_old: {
        doCheck = false;
      });

      # elixir,elixir-ls, and hex are using the same version elixir
      #
      elixir = beamPackages.elixir_1_16;
      # elixir-ls needs to be compiled with elixir_ls.release2 for the latest otp version
      elixir-ls = (beamPackages.elixir-ls.override { inherit elixir; }).overrideAttrs (_old: {
        buildPhase = ''
          runHook preBuild
          mix do compile --no-deps-check, elixir_ls.release2
          runHook postBuild
        '';
      });
      hex = beamPackages.hex.override { inherit elixir; };

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
      integrationTestingTools =
        with pkgs;
        [
          chromedriver
          selenium-server-standalone
        ]
        ++ lib.optionals (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.chromium) [ chromium ];

      darwinOnlyTools = with pkgs; [
        podman
        podman-compose
        pkgs.darwin.apple_sdk.frameworks.Security
        pkgs.darwin.apple_sdk.frameworks.CoreServices
        pkgs.darwin.apple_sdk.frameworks.CoreFoundation
        pkgs.darwin.apple_sdk.frameworks.Foundation
      ];

      nativeBuildInputs =
        with pkgs;
        [
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
          flock

          skopeo # Use for pushing docker
          wireguard-tools
          age # secure out of band communications
          nixpkgs-fmt

          awscli2
          ssm-session-manager-plugin
        ]
        ++ elixirNativeTools
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
        export MIX_ARCHIVES=$MIX_HOME/archives
        mkdir -p $MIX_ARCHIVES

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
            || mix local.rebar --if-missing --force rebar3 ${rebar3}/bin/rebar3


        # Install hex if it's not there
        find $MIX_HOME -type f -name 'hex.app' -print0 | grep -qz . \
            || mix local.hex --force
        popd &> /dev/null
      '';
    in
    {
      devShells.default = pkgs.mkShell {
        inherit nativeBuildInputs buildInputs shellHook;
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
        LC_CTYPE = "en_US.UTF-8";
        ERL_AFLAGS = "-kernel shell_history enabled";

        inputsFrom = [
          config.mission-control.devShell
          config.flake-root.devShell
        ];
      };
    };
}
