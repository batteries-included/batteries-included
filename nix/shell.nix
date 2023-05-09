{ inputs, ... }:

{

  perSystem = { system, ... }:
    let
      overlays = [ (import inputs.rust-overlay) ];
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      beam = pkgs.beam;
      beamPackages = beam.packagesWith beam.interpreters.erlang;
      erlang = beamPackages.erlang;
      elixir = beamPackages.elixir;
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
        jq
        k9s
        kind
        kubectl

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
      ++ lib.optionals pkgs.stdenv.isLinux linuxOnlyTools;


      buildInputs = with pkgs; [
        openssl
        glibcLocales
      ];

      shellHook = ''
        # go to the top level.
        pushd $(git rev-parse --show-toplevel || echo ".")

        # this allows mix to work on the local directory
        export MIX_HOME=$PWD/.nix-mix
        mkdir -p $MIX_HOME

        export HEX_HOME=$PWD/.nix-hex
        mkdir -p $HEX_HOME

        export PATH=$MIX_HOME/bin:$PATH
        export PATH=$HEX_HOME/bin:$PATH

        pushd platform_umbrella
        mix local.rebar --if-missing rebar3 ${rebar3}/bin/rebar3 || true;
        mix local.hex --force --if-missing || true;
        popd

        # This keeps cargo self contained in this dir
        export CARGO_HOME=$PWD/.nix-cargo
        mkdir -p $CARGO_HOME

        popd
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
      };
    };
}
