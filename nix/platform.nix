{ inputs, self, ... }:
{
  perSystem =
    { lib, pkgs, ... }:
    let
      inherit (inputs.gitignore.lib) gitignoreSource;
      inherit (pkgs) pkg-config;
      inherit (pkgs) gcc;
      inherit (pkgs) openssl;
      inherit (pkgs) beam;
      inherit (pkgs) cmake;

      inherit (pkgs) python312;
      nodejs = pkgs.nodejs_22;

      LANG = "C.UTF-8";
      src = gitignoreSource ./../platform_umbrella;
      version = "0.13.0";

      beamPackages = beam.packagesWith beam.interpreters.erlang_27;
      inherit (beamPackages) erlang;
      elixir = beamPackages.elixir_1_17;
      hex = beamPackages.hex.override { inherit elixir; };
      rebar3 = beamPackages.rebar3.overrideAttrs (_old: {
        doCheck = false;
        chechPhase = "";
      });

      safeRev = self.shortRev or self.dirtyShortRev;
      fakeGit = pkgs.writeScriptBin "git" "echo \"${safeRev}\"";

      npmlock2nix = pkgs.callPackages inputs.npmlock2nix { };

      mixTestFodDeps = beamPackages.fetchMixDeps {
        pname = "mix-deps-platform-test";
        inherit
          src
          version
          LANG
          elixir
          rebar3
          ;
        mixEnv = "test";
        #sha256 = lib.fakeSha256;
        sha256 = "sha256-3SBYfAC44LqnfgvXGymwoO5g5op9lKWSuC/f5zMnq7I";
      };

      # mix fixed output derivation dependencies
      # Nix usually doesn't allow any step to reach the internet since that can
      # introduce some changes in output. These derivations have to have the
      # output hash fixed which allows them network access. So we say this step
      # should result in X.
      # TODO(jdt): somehow use the hashes from mix.lock instead
      mixFodDeps = beamPackages.fetchMixDeps {
        pname = "mix-deps-platform";
        inherit
          src
          version
          LANG
          elixir
          ;
        #sha256 = lib.fakeSha256;
        sha256 = "sha256-xrYn8mP93E5pFwWwfpDrERQnQTSFfsKyRiyvhVbIcAE=";
      };

      control-server = pkgs.callPackage ./platform-release.nix {
        inherit
          version
          src
          mixFodDeps
          pkgs
          self
          ;
        inherit erlang elixir hex;
        inherit npmlock2nix nodejs;
        inherit
          pkg-config
          gcc
          openssl
          cmake
          python312
          fakeGit
          ;
        inherit gitignoreSource;

        pname = "control_server";
        mixEnv = "prod";
      };

      kube-bootstrap = beamPackages.mixRelease {
        inherit src version mixFodDeps;
        inherit erlang elixir hex;
        MIX_ENV = "prod";
        LANG = "C.UTF-8";
        pname = "kube_bootstrap";

        nativeBuildInputs = [
          gcc
          cmake
          pkg-config
          cmake
          python312
          fakeGit
        ];
        buildInputs = [ openssl ];
        installPhase = ''
          export APP_VERSION="${version}"
          export APP_NAME="batteries_included"
          export RELEASE="kube_bootstrap"
          mix do compile --force, \
          release --no-deps-check --overwrite --path "$out" kube_bootstrap
        '';
      };

      home-base = pkgs.callPackage ./platform-release.nix {
        inherit version src mixFodDeps;
        inherit erlang elixir hex;
        inherit npmlock2nix nodejs;
        inherit
          pkg-config
          gcc
          openssl
          cmake
          python312
          fakeGit
          ;
        inherit gitignoreSource;

        pname = "home_base";
        mixEnv = "prod";
      };

      credo = pkgs.callPackage ./mix-command.nix {
        inherit version src pkgs;
        inherit erlang elixir hex;
        inherit
          pkg-config
          gcc
          openssl
          cmake
          python312
          fakeGit
          ;
        inherit rebar3;

        pname = "platform";
        mixEnv = "test";
        mixFodDeps = mixTestFodDeps;
        command = "credo";
      };

      dialyzer = pkgs.callPackage ./mix-command.nix {
        inherit version src pkgs;
        inherit erlang elixir hex;
        inherit
          pkg-config
          gcc
          openssl
          cmake
          python312
          fakeGit
          ;
        inherit rebar3;

        pname = "platform";
        mixEnv = "test";
        mixFodDeps = mixTestFodDeps;
        command = "dialyzer";
      };
    in
    {
      packages = {
        inherit home-base control-server kube-bootstrap;
      };
      checks = {
        inherit credo dialyzer;
      };
    };
}
