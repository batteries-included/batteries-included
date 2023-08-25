{ ... }:

{
  perSystem = { lib, config, ... }:
    {
      mission-control = {
        wrapperName = "bi";

        scripts = {

          fmt = {
            description = "Format the codebase";
            category = "code";
            exec = ''
              treefmt
              ex-fmt
            '';
          };

          ex-fmt = {
            description = "Format elixir codebase";
            category = "elixir";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              pushd platform_umbrella &> /dev/null
              trap 'popd &> /dev/null' EXIT
              mix format
            '';
          };

          ex-test = {
            description = "Run stale tests";
            category = "elixir";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              pushd platform_umbrella &> /dev/null
              trap 'popd &> /dev/null' EXIT
              mix test --trace --stale
            '';
          };

          ex-test-quick = {
            description = "Run tests excluding @tag slow";
            category = "elixir";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              pushd platform_umbrella &> /dev/null
              trap 'popd &> /dev/null' EXIT
              mix test --trace --exclude slow --cover --export-coverage default --warnings-as-errors
              mix test.coverage
            '';
          };

          ex-test-deep = {
            description = "Run all tests with coverage and all that jazz";
            category = "elixir";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              pushd platform_umbrella &> /dev/null
              trap 'popd &> /dev/null' EXIT
              mix deps.get
              mix compile --force --warnings-as-errors
              mix ecto.reset
              mix test --trace --slowest 10 --cover --export-coverage default --warnings-as-errors
              mix test.coverage
            '';
          };

          ex-deep-clean = {
            description = "Really clean the elixir codebase";
            category = "elixir";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              pushd platform_umbrella &> /dev/null
              trap 'popd &> /dev/null' EXIT
              mix clean --deps
              rm -rf _build deps .elixir_ls
              find . -name node_modules -print0 | xargs -0 rm -rf || true
              find . -name assets | grep priv | xargs rm -rf || true
              mix deps.get && mix compile --force
            '';
          };

          m = {
            description = "Run mix commands";
            category = "elixir";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              pushd platform_umbrella &> /dev/null
              trap 'popd &> /dev/null' EXIT
              mix "$@"
            '';
          };

          bootstrap = {
            description = "Bootstrap the dev environment";
            category = "dev";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              trap 'trap - SIGTERM && kill -- -$$' SIGINT SIGTERM EXIT
              ${lib.getExe config.packages.bcli} dev -vv --platform-dir=platform_umbrella
              echo "Exited"
            '';
          };

          uninstall = {
            description = "Uninstall everything from the kube cluster";
            category = "dev";
            exec = ''
              ${lib.getExe config.packages.bcli} uninstall -vv
            '';
          };

          build = {
            description = "Build the given flake.";
            category = "dev";
            exec = ''nix build ".#''${1:-""}"'';
          };

          stop = {
            description = "Stop the kind cluster and all things";
            category = "dev";
            exec = ''
              ${lib.getExe config.packages.bcli} stop -vv
            '';
          };

          dev = {
            description = "Start dev environment";
            category = "dev";
            exec = ''
              m phx.server
            '';
          };

          dev-iex = {
            description = "Start dev environment with iex";
            category = "dev";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              pushd platform_umbrella &> /dev/null
              trap 'popd &> /dev/null' EXIT
              iex -S mix phx.server
            '';
          };

          gen-static-specs = {
            description = "Generate static specs";
            category = "dev";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              pushd platform_umbrella &> /dev/null
              mix "do" clean, compile --force
              mix gen.static.installations "../cli/tests/resources/specs"
              mix gen.static.installations "../static/public/specs"
              popd &> /dev/null
              treefmt
            '';
          };

          nuke-test-db = {
            description = "Reset test DB";
            category = "dev";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              export MIX_ENV=test
              m "do" compile --force, ecto.reset
            '';
          };

          push-aws = {
            description = "Push to AWS";
            category = "ops";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              DIR=ops/aws/ansible
              ansible-playbook -i "$DIR/inventory.yml" "$DIR/all.yml" -b
            '';
          };

          gen-keys = {
            description = "Generate SSH and wireguard keys";
            category = "ops";
            exec = builtins.readFile ./scripts/gen-keys.sh;
          };

          gen-wg-client-config = {
            description = "Generate SSH and wireguard keys";
            category = "ops";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              KEYS_DIR="ops/aws/keys"
              CLIENT_NAME=''${1:-wireguard-client}
              CLIENT_KEY=$(cat "$KEYS_DIR/$CLIENT_NAME")
              SERVER_PUBKEY=$(cat "$KEYS_DIR/gateway.pub")

              cat <<END
              [Interface]
              PrivateKey = $CLIENT_KEY
              Address = 10.250.0.1/32

              [Peer]
              PublicKey = $SERVER_PUBKEY
              AllowedIPs = 10.250.0.0/24, 10.0.0.0/16
              Endpoint = pub-wg.batteriesincl.com:51820
              END
            '';
          };

          package-challenge = {
            description = ''
              Package up candidate challenge: "bi package-challenge candidate-name [destination-dir] [challenge]"
            '';
            category = "recruiting";
            exec = builtins.readFile ./scripts/package-challenge.sh;
          };

          # template = {
          #   description = "";
          #   category = "";
          #   exec = ''
          # '';
          # };

        };
      };
    };
}
