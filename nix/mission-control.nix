_: {
  perSystem =
    { lib, pkgs, ... }:
    {
      mission-control = {
        wrapperName = "bix";

        scripts = {
          ex-test-setup = {
            description = "Run test setup";
            category = "elixir";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              do_portforward_controlserver

              export MIX_ENV=test
              m ecto.reset
            '';
          };

          ex-test = {
            description = "Run stale tests";
            category = "elixir";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              do_portforward_controlserver

              m test --trace --stale --warnings-as-errors --all-warnings
            '';
          };

          ex-test-quick = {
            description = "Run tests excluding @tag slow";
            category = "elixir";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              do_portforward_controlserver

              export MIX_ENV=test
              m "do" \
                test --trace --exclude slow --cover --export-coverage default --all-warnings --warnings-as-errors, \
                test.coverage
            '';
          };

          ex-test-deep = {
            description = "Run all tests with coverage and all that jazz";
            category = "elixir";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              do_portforward_controlserver

              pushd platform_umbrella &> /dev/null
              export MIX_ENV=test
              mix deps.get
              mix compile --warnings-as-errors
              mix ecto.reset
              mix test --trace --slowest 10 --cover --export-coverage default --warnings-as-errors --all-warnings
              mix test.coverage
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

          ex-int-test = lib.mkIf (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.chromium) {
            description = "Run integration tests.";
            category = "elixir";

            exec = "${builtins.readFile ./scripts/common-functions.sh}
                    # TODO: This should be overridable os OSX can supply a local chrome
                    # however I haven't tested it so /shrug
                    chromium_binary=${pkgs.chromium}/bin/chromium
                    export WALLABY_CHROME_BINARY=\${WALLABY_CHROME_BINARY:-\$chromium_binary}
                    do_integration_test \"$@\"
              ";
          };

          ex-int-test-deep = lib.mkIf (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.chromium) {
            description = "Run integration tests.";
            category = "elixir";

            exec = "${builtins.readFile ./scripts/common-functions.sh}
                    chromium_binary=${pkgs.chromium}/bin/chromium
                    export WALLABY_CHROME_BINARY=\${WALLABY_CHROME_BINARY:-\$chromium_binary}
                    do_integration_test_deep \"$@\"
              ";
          };

          bootstrap = {
            description = "Bootstrap the dev environment";
            category = "fullstack";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              do_bootstrap "$@"
            '';
          };

          dev = {
            description = "Start dev environment";
            category = "dev";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              do_portforward_controlserver

              pushd platform_umbrella &> /dev/null
              iex -S mix phx.server
            '';
          };

          dev-no-iex = {
            description = "Start dev environment without iex";
            category = "dev";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              do_portforward_controlserver

              pushd platform_umbrella &> /dev/null
              mix phx.server
            '';
          };

          build = {
            description = "Build the given flake.";
            category = "dev";
            exec = ''
              [[ -z ''${TRACE:-""} ]] || set -x
              flake=".#''${1:-""}"
              shift
              [[ $(git ls-files --others --exclude-standard | wc -l) -gt 0 ]] \
                  && echo -e '\e[1;31mUntracked files! Dont forget to add them if needed for build!!!\e[0m'
              nix build "$flake" "$@"
            '';
          };

          nuke-test-db = {
            description = "Reset test DB";
            category = "dev";
            exec = ''
              ${builtins.readFile ./scripts/common-functions.sh}
              do_portforward_controlserver

              export MIX_ENV=test
              m "do" compile --force, ecto.reset
            '';
          };
        };
      };
    };
}
