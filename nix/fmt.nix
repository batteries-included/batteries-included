{ ... }:

{
  perSystem = { config, pkgs, ... }:
    {

      treefmt.config = {
        inherit (config.flake-root) projectRootFile;
        package = pkgs.treefmt;

        programs.nixpkgs-fmt.enable = true;
        programs.deadnix.enable = true;
        programs.rustfmt.enable = true;
        programs.prettier.enable = true;
        programs.shfmt.enable = true;
        programs.terraform.enable = true;

        settings.formatter.prettier.excludes = [
          ".nix-cargo/**"
          ".nix-hex/**"
          ".nix-mix/**"
          "result/**"
          ".jj/**"
          "./platform_umbrella/_build/*"
          "./platform_umbrella/deps/*"
          "**/.elixir_ls/**"
          "**/node_modules/**"
        ];
      };

    };
}
