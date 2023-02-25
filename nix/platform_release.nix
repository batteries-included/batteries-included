{ pname, src, version, pkgs, nodejs, mixEnv ? "prod", npmlock2nix, ... }:
let

  MIX_ENV = mixEnv;
  LANG = "C.UTF-8";

  beam = pkgs.beam;

  inherit (pkgs) lib;
  beamPackages = beam.packagesWith beam.interpreters.erlang;

  # all elixir and erlange packages
  erlang = beamPackages.erlang;
  elixir = beamPackages.elixir;
  esbuild = pkgs.esbuild;
  rustToolChain = pkgs.rust-bin.nightly.latest.default;
  pkg-config = pkgs.pkg-config;
  gcc = pkgs.gcc;
  libgcc = pkgs.libgcc;


  mixFodDeps = beamPackages.fetchMixDeps {
    pname = "mix-deps-${pname}";
    inherit src version MIX_ENV LANG;
    sha256 = "cRPssvVoi7FU1+z1fo/pW85xskYsNYjPdCHZpmBpJQk=";
  };

  homePriv = pkgs.callPackage ./priv.nix {
    inherit pname version nodejs npmlock2nix;
    name = "home_priv";
    src = src + /apps/home_base_web/assets/.;
  };

  controlPriv = pkgs.callPackage ./priv.nix {
    inherit pname version nodejs npmlock2nix;
    name = "ctrl_priv";
    src = src + /apps/control_server_web/assets/.;
  };

  installHook = { release, version }: ''
    export APP_VERSION="${version}"
    export APP_NAME="batteries_included"
    export RELEASE="${release}"
    runHook preInstall
    mix compile --force
    mix release --no-deps-check --overwrite --path "$out" ${release}
  '';
in
beamPackages.mixRelease {
  inherit src pname version mixFodDeps MIX_ENV LANG erlang elixir;

  nativeBuildInputs = [ gcc rustToolChain pkg-config ];
  buildInputs = [ pkgs.openssl_1_1 gcc libgcc ];

  postUnpack = ''
    mkdir -p apps/control_server_web/priv/static/assets/
    mkdir -p apps/home_base_web/priv/static/assets/

    cp ${controlPriv}/* apps/control_server_web/priv/static/assets/
    cp ${homePriv}/* apps/home_base_web/priv/static/assets/
  '';

  installPhase = installHook { release = pname; inherit version; };

  postBuild = ''
    mix do deps.loadpaths --no-deps-check, phx.digest
    mix phx.digest --no-deps-check
  '';
}

