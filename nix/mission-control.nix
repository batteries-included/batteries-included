{ ... }:

{
  perSystem = { lib, config, pkgs, ... }:
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
              m format
            '';
          };

          ex-test-setup = {
            description = "Run test setup";
            category = "elixir";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              export MIX_ENV=test
              m ecto.reset
            '';
          };


          ex-test = {
            description = "Run stale tests";
            category = "elixir";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              m test --trace --stale
            '';
          };

          ex-test-quick = {
            description = "Run tests excluding @tag slow";
            category = "elixir";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              export MIX_ENV=test
              m "do" \
                test --trace --exclude slow --cover --export-coverage default --warnings-as-errors, \
                test.coverage
            '';
          };

          ex-test-deep = {
            description = "Run all tests with coverage and all that jazz";
            category = "elixir";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              pushd platform_umbrella &> /dev/null
              trap 'popd &> /dev/null' EXIT
              export MIX_ENV=test
              mix deps.get
              mix compile --force --warnings-as-errors
              mix ecto.reset
              mix test --trace --slowest 10 --cover --export-coverage default --warnings-as-errors
              mix test.coverage
            '';
          };

          ex-test-int = lib.mkIf (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.chromium) {
            description = "Run integration tests. Used in CI as well.";
            category = "elixir";

            exec = ''
              export WALLABY_CHROME_BINARY=${pkgs.chromium}/bin/chromium
              ${builtins.readFile ./scripts/integration-test.sh}
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

          ex-watch = {
            description = "Watch for changes to elixir source";
            category = "elixir";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              ${lib.getExe' pkgs.fswatch "fswatch"} \
                --one-per-batch \
                --event=Updated \
                --recursive \
                platform_umbrella/apps/
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
              # shellcheck disable=2046
              ${lib.getExe config.packages.bcli} dev \
                $([[ -z ''${TRACE:-""} ]] || echo "-vv") \
                --platform-dir=platform_umbrella \
                --static-dir=static
              echo "Exited"
            '';
          };

          clean = {
            description = "Clean the working tree";
            category = "dev";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              git clean -idx \
                -e .env \
                -e .iex.exs
            '';
          };

          uninstall = {
            description = "Uninstall everything from the kube cluster";
            category = "dev";
            exec = ''
              # shellcheck disable=2046
              ${lib.getExe config.packages.bcli} uninstall $([[ -z ''${TRACE:-""} ]] || echo "-vv")
            '';
          };

          build = {
            description = "Build the given flake.";
            category = "dev";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              flake=".#''${1:-""}"
              shift
              nix build "$flake" "$@"
            '';
          };

          stop = {
            description = "Stop the kind cluster and all things";
            category = "dev";
            exec = ''
              # shellcheck disable=2046
              ${lib.getExe config.packages.bcli} stop $([[ -z ''${TRACE:-""} ]] || echo "-vv")
            '';
          };

          dev = {
            description = "Start dev environment";
            category = "dev";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              pushd platform_umbrella &> /dev/null
              trap 'popd &> /dev/null' EXIT
              iex -S mix phx.server
            '';
          };

          dev-no-iex = {
            description = "Start dev environment without iex";
            category = "dev";
            exec = ''
              m phx.server
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
