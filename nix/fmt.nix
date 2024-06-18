{ inputs, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    let
      nodejs = pkgs.nodejs_22;
      npmlock2nix = pkgs.callPackages inputs.npmlock2nix { };
      node_modules = npmlock2nix.v2.node_modules {
        src = ./fmt/.;
        inherit nodejs;
      };
    in
    {
      treefmt.config = {
        inherit (config.flake-root) projectRootFile;
        package = pkgs.treefmt;

        programs = {
          nixfmt-rfc-style.enable = true;
          deadnix.enable = true;
          statix.enable = true;

          prettier = {
            enable = true;
            settings = {
              semi = true;
              singleQuote = true;
              bracketSameLine = true;
              trailingComma = "es5";
              proseWrap = "always";
              tabWidth = 2;

              plugins = [
                "${node_modules}/node_modules/prettier-plugin-astro/dist/index.js"
                # Must come last apparently /shrug
                "${node_modules}/node_modules/prettier-plugin-tailwindcss/dist/index.mjs"
              ];
              # Taken from:
              # https://github.com/withastro/prettier-plugin-astro?tab=readme-ov-file#recommended-configuration
              overrides = [
                {
                  files = [ "*.astro" ];
                  parser = "astro";
                }
              ];
            };
          };

          shfmt.enable = true;
          gofmt.enable = true;
        };

        settings = {
          global.excludes = [
            "./platform_umbrella/_build/**"
            "./platform_umbrella/deps/**"
            "./cli/target/**"
            "./result/**"
            ".jj/**"
            ".git/**"
            ".nix-cargo/**"
            ".nix-hex/**"
            ".nix-mix/**"
            "**/target/**"
            "**/.elixir_ls/**"
            "**/node_modules/**"
          ];
        };
      };
    };
}
