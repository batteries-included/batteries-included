{ inputs, ... }:

{

  perSystem = { system, nixpkgs, rust-overlay, ... }:
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

      elixirNativeTools = with pkgs; [
        erlang
        elixir

        rebar
        rebar3
        hex

        mix2nix
        postgresql

        awscli2
        bind
      ];

      rustNativeBuildTools = with pkgs; [
        rust-bin.stable.latest.complete
        pkg-config
        cargo-flamegraph
        postgresql
      ];


      linuxOnlyTools = with pkgs; [
        # Track when files change for css updates
        inotify-tools
      ];

      darwinOnlyTools = [ ];

      nativeBuildInputs = with pkgs; [
        # node is needed, because
        # javascript won for better or worse
        nodejs

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
      ++ elixirNativeTools
      ++ rustNativeBuildTools
      ++ lib.optionals pkgs.stdenv.isDarwin darwinOnlyTools
      ++ lib.optionals pkgs.stdenv.isLinux linuxOnlyTools;


      buildInputs = with pkgs; [
        openssl_1_1
      ];

      shellHook = ''
        # this allows mix to work on the local directory
        mkdir -p .nix-mix
        mkdir -p .nix-hex
        export MIX_HOME=$PWD/.nix-mix
        export HEX_HOME=$PWD/.nix-hex
        export PATH=$MIX_HOME/bin:$PATH
        export PATH=$HEX_HOME/bin:$PATH

        mix local.rebar --if-missing rebar3 ${rebar3}/bin/rebar3;
        mix local.hex --force --if-missing
      '';


    in
    {
      devShells.default = pkgs.mkShell {
        inherit nativeBuildInputs buildInputs shellHook;
        LANG = "en_US.UTF-8";
        RUST_BACKTRACE = 1;
        ERL_AFLAGS = "-kernel shell_history enabled";
      };
    };
}
