{ inputs, ... }:

{

  perSystem = { system, config, lib, ... }:
    let
      overlays = [ (import inputs.rust-overlay) ];
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      beam = pkgs.beam;
      beamPackages = beam.packagesWith beam.interpreters.erlang_26;
      erlang = beamPackages.erlang;
      elixir = beamPackages.elixir_1_15;
      rebar = beamPackages.rebar;
      rebar3 = beamPackages.rebar3;
      elixir-ls = beamPackages.elixir-ls;

      elixirNativeTools = with pkgs; [
        erlang
        elixir

        rebar
        rebar3
        hex
        elixir-ls
        sqlite

        mix2nix
        postgresql

        bind
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
      ];


      nativeBuildInputs = with pkgs; [
        # node is needed, because
        # javascript won for better or worse
        nodejs

        # Command line tools
        cachix
        jq
        k9s
        kind
        kubectl
        kubernetes-helm

        # Use for pushing docker
        skopeo
        terraform
        wireguard-tools
        ansible
        awscli2
      ]
      ++ elixirNativeTools
      ++ rustNativeBuildTools
      ++ lib.optionals pkgs.stdenv.isDarwin darwinOnlyTools
      ++ lib.optionals pkgs.stdenv.isLinux linuxOnlyTools
      ++ [ config.treefmt.build.wrapper ];


      buildInputs = with pkgs; [
        openssl
        glibcLocales
      ];

      shellHook = ''
        # NOTE(jdt): try very hard not to run mix commands here.
        # they take a bit to start and execute even if they don't do anything

        # go to the top level.
        pushd $(git rev-parse --show-toplevel || echo ".") &> /dev/null

        # this allows mix to work on the local directory
        export MIX_HOME=$PWD/.nix-mix
        mkdir -p $MIX_HOME

        export HEX_HOME=$PWD/.nix-hex
        mkdir -p $HEX_HOME

        export PATH=$MIX_HOME/bin:$PATH
        export PATH=$HEX_HOME/bin:$PATH

        pushd platform_umbrella &> /dev/null
        [[ $(find $MIX_HOME -type f -name 'rebar3' -executable -print0 | grep -qz .) ]] \
            || mix local.rebar --if-missing rebar3 ${rebar3}/bin/rebar3
        [[ $(find $MIX_HOME -type d -name 'hex-*' -print0 | grep -qz . ) ]] \
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

        inputsFrom = [ config.mission-control.devShell ];
      };
    };
}
