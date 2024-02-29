{ pname
, src
, version
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
, gitignoreSource
, ...
}:
let

  MIX_ENV = mixEnv;
  LANG = "C.UTF-8";

  node_modules = npmlock2nix.v2.node_modules {
    src = gitignoreSource ./../platform_umbrella/apps/${pname}_web/assets/.;
    inherit nodejs;
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

  nativeBuildInputs = [ gcc rustToolChain pkg-config nodejs ];
  buildInputs = [ openssl ];

  postBuild = ''
    ln -sf ${node_modules}/node_modules ./apps/${pname}_web/assets/node_modules
    npm run css:deploy --prefix ./apps/${pname}_web/assets
    npm run js:deploy --prefix ./apps/${pname}_web/assets

    mix do deps.loadpaths --no-deps-check, phx.digest
    rm -rf ./apps/${pname}_web/assets/node_modules
  '';

  installPhase = installHook { release = pname; inherit version; };
}
