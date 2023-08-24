{ pname
, src
, version
, pkgs
, gcc
, openssl
, rustToolChain
, pkg-config
, mixEnv ? "prod"
, npmlock2nix
, nodejs
, beamPackages
, erlang
, elixir
, hex
, mixFodDeps
, ...
}:
let

  MIX_ENV = mixEnv;
  LANG = "C.UTF-8";

  priv = pkgs.callPackage ./priv.nix {
    inherit pname version nodejs npmlock2nix;
    name = "${pname}_priv";
    src = src + /apps/${pname}_web/assets/.;
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
  inherit src pname version mixFodDeps MIX_ENV LANG;
  inherit erlang elixir hex;

  nativeBuildInputs = [ gcc rustToolChain pkg-config ];
  buildInputs = [ openssl gcc ];

  postUnpack = ''
    mkdir -p apps/${pname}_web/priv/static/assets/
    cp -r ${priv}/* apps/${pname}_web/priv/static/assets/
  '';

  installPhase = installHook { release = pname; inherit version; };

  postBuild = ''
    mix do deps.loadpaths --no-deps-check, phx.digest
    mix phx.digest --no-deps-check
  '';
}
