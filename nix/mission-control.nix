{ ... }:

{
  perSystem = { lib, pkgs, ... }:
    {
      mission-control = {
        wrapperName = "bix";

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
              ${builtins.readFile ./scripts/common-functions.sh}
              portforward_controlserver

              export MIX_ENV=test
              m ecto.reset
            '';
          };


          ex-test = {
            description = "Run stale tests";
            category = "elixir";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              portforward_controlserver

              m test --trace --stale
            '';
          };

          ex-test-quick = {
            description = "Run tests excluding @tag slow";
            category = "elixir";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              portforward_controlserver

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
              ${builtins.readFile ./scripts/common-functions.sh}
              portforward_controlserver

              pushd platform_umbrella &> /dev/null
              export MIX_ENV=test
              mix deps.get
              mix compile --warnings-as-errors
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
              mix "$@"
            '';
          };

          bootstrap = {
            description = "Bootstrap the dev environment";
            category = "dev";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              do_bootstrap "$@"
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
              bcli uninstall $([[ -z ''${TRACE:-""} ]] || echo "-vv")
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
              ${builtins.readFile ./scripts/common-functions.sh}
              do_stop "$@"
            '';
          };

          dev = {
            description = "Start dev environment";
            category = "dev";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              portforward_controlserver

              pushd platform_umbrella &> /dev/null
              iex -S mix phx.server
            '';
          };

          dev-no-iex = {
            description = "Start dev environment without iex";
            category = "dev";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              portforward_controlserver

              pushd platform_umbrella &> /dev/null
              mix phx.server
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
              ${builtins.readFile ./scripts/common-functions.sh}
              portforward_controlserver

              export MIX_ENV=test
              m "do" compile --force, ecto.reset
            '';
          };

          force-remove-namespace = {
            description = "Forcefully remove the given namespace by removing finalizers";
            category = "dev";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              [[ "$#" -ne 1 ]] && { echo "Missing namespace argument"; exit 1;}
              NAMESPACE="$1"

              # shellcheck disable=2046
              kubectl get ns -o json $([[ -z ''${TRACE:-""} ]] || echo "-v=4") "$NAMESPACE"  \
                  | jq '.spec.finalizers = []' \
                  | kubectl replace $([[ -z ''${TRACE:-""} ]] || echo "-v=4") \
                      --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f -
            '';
          };

          package-challenge = {
            description = ''
              Package up candidate challenge: "bix package-challenge candidate-name [destination-dir] [challenge]"
            '';
            category = "recruiting";
            exec = builtins.readFile ./scripts/package-challenge.sh;
          };
        };
      };
    };
}
