{ inputs, ... }:

{
  perSystem = { self', config, pkgs, ... }:
    {

      treefmt.config = {
        inherit (config.flake-root) projectRootFile;
        package = pkgs.treefmt;

        programs.nixpkgs-fmt.enable = true;
        programs.rustfmt.enable = true;
        programs.prettier.enable = true;
        programs.shfmt.enable = true;
        programs.terraform.enable = true;

        settings.formatter.prettier.excludes = [
          ".nix-cargo/*"
          ".nix-hex/*"
          ".nix-mix/*"
          ".jj/*"
          "./platform_umbrella/apps/control_server_web/assets/node_modules/*"
          "./platform_umbrella/apps/home_base_web/assets/node_modules/*"
          "./project_templates/web/pastebin/node_modules/*"
          "./static/node_modules/*"
          "./platform_umbrella/_build/*"
          "./platform_umbrella/deps/*"
          "./platform_umbrella/.elixir_ls/*"
        ];
      };

    };
}
