{ inputs, ... }:

{
  perSystem = { self', ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixpkgs-fmt.enable = true;
        programs.rustfmt.enable = true;
        programs.prettier.enable = true;
        programs.shfmt.enable = true;
        programs.terraform.enable = true;
      };
    };
}
