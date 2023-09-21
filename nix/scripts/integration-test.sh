[[ -z ${TRACE:-""} ]] || set -x
export MIX_ENV=integration

setupAssets() {
  pushd "${1}"
  npm install
  npm run css:deploy:dev
  npm run js:deploy:dev
  popd
}

# Get the deps and compile everything
# This makes sure to compile
# before ecto.reset does (which wouldn't
# compile all protocols and leave the _build
# in a bad state)
m "do" \
  deps.get, \
  compile --warnings-as-errors

setupAssets platform_umbrella/apps/control_server_web/assets
setupAssets platform_umbrella/apps/home_base_web/assets

# Ensure that we have a table and it's clear
m ecto.reset

m test --trace --warnings-as-errors --slowest 10
