{ pname
, version
, src
, pkgs
, nativeBuildInputs ? [ ]
, buildInputs ? [ ]
, mixEnv ? "test"
, mixFodDeps ? null
, rustToolChain
, pkg-config
, gcc
, openssl
, erlang
, elixir
, hex
, rebar3
, command
, ...
}:
let
  makeWrapper = pkgs.makeWrapper;
  git = pkgs.git;
in
pkgs.stdenv.mkDerivation ({

  doCheck = true;

  name = "mix-command-${pname}-${command}";
  inherit pname version src;
  nativeBuildInputs = nativeBuildInputs ++ [
    erlang
    elixir
    hex
    rustToolChain
    pkg-config
    gcc
    openssl
  ];
  buildInputs = buildInputs;

  MIX_ENV = mixEnv;
  HEX_OFFLINE = 1;
  LANG = "C.UTF-8";


  # the api with `mix local.rebar rebar path` makes a copy of the binary
  # some older dependencies still use rebar
  MIX_REBAR3 = "${rebar3}/bin/rebar3";

  postUnpack = ''
    export HEX_HOME="$TEMPDIR/hex"
    export MIX_HOME="$TEMPDIR/mix"

    # Rebar
    export REBAR_GLOBAL_CONFIG_DIR="$TEMPDIR/rebar3"
    export REBAR_CACHE_DIR="$TEMPDIR/rebar3.cache"

    # compilation of the dependencies will require
    # that the dependency path is writable
    # thus a copy to the TEMPDIR is inevitable here
    export MIX_DEPS_PATH="$TEMPDIR/deps"
    cp --no-preserve=mode -R "${mixFodDeps}" "$MIX_DEPS_PATH"

    ls -alR $MIX_DEPS_PATH
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
})
