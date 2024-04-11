{ ... }:

{
  perSystem = { config, pkgs, ... }:
    {

      treefmt.config = {
        inherit (config.flake-root) projectRootFile;
        package = pkgs.treefmt;

        programs.nixpkgs-fmt.enable = true;
        programs.deadnix.enable = true;
        programs.prettier.enable = true;
        programs.shfmt.enable = true;
        programs.gofmt.enable = true;

        settings = {
          global.excludes = [
            "./platform_umbrella/_build/*"
            "./platform_umbrella/deps/*"
            "./cli/target/*"
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
