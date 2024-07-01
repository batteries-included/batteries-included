{
  pname,
  version,
  src,
  pkgs,
  nativeBuildInputs ? [ ],
  buildInputs ? [ ],
  mixEnv ? "test",
  mixFodDeps ? null,
  pkg-config,
  gcc,
  cmake,
  python312,
  openssl,
  erlang,
  elixir,
  hex,
  rebar3,
  command,
  fakeGit,
  ...
}:
pkgs.stdenv.mkDerivation {
  doCheck = true;

  name = "mix-command-${pname}-${command}";
  inherit pname version src;
  nativeBuildInputs = nativeBuildInputs ++ [
    erlang
    elixir
    hex
    pkg-config
    gcc
    cmake
    python312
    openssl
    fakeGit
  ];
  inherit buildInputs;

  MIX_ENV = mixEnv;
  HEX_OFFLINE = 1;
  LANG = "C.UTF-8";

  # the api with `mix local.rebar rebar path` makes a copy of the binary
  # some older dependencies still use rebar
  MIX_REBAR3 = "${rebar3}/bin/rebar3";

  # Override the configurePhase to ensure
  # that it keeps off the cmake files in libdecaf
  configurePhase = ''
    runHook preConfigure
    export TEMPDIR=$(mktemp -d)
    export HEX_HOME="$TEMPDIR/hex"
    export MIX_HOME="$TEMPDIR/mix"
    export ELIXIR_MAKE_CACHE_DIR="$TEMPDIR/elixir.cache"

    # Rebar
    export REBAR_GLOBAL_CONFIG_DIR="$TEMPDIR/rebar3"
    export REBAR_CACHE_DIR="$TEMPDIR/rebar3.cache"
    runHook postConfigure
  '';

  postUnpack = ''
    # compilation of the dependencies will require
    # that the dependency path is writable
    # thus a copy to the TEMPDIR is inevitable here
    export MIX_DEPS_PATH="$TEMPDIR/deps"
    cp --no-preserve=mode -R "${mixFodDeps}" "$MIX_DEPS_PATH"
  '';

  buildPhase = ''
    mix deps.compile --no-deps-check --skip-umbrella-children
    mix compile --no-deps-check --warnings-as-errors
  '';

  checkPhase = ''
    mix ${command} && echo Success
  '';

  installPhase = ''
    touch $out
  '';
}
