{ inputs, ... }:

{
  perSystem = { pkgs, ... }:
    let
      inherit (inputs.gitignore.lib) gitignoreSource;

      nodejs = pkgs.nodejs;
      npmlock2nix = pkgs.callPackages inputs.npmlock2nix { };
      version = "0.12.2";
    in
    {
      packages.pastebin-static = npmlock2nix.v2.build {
        inherit nodejs version;
        pname = "pastebin";
        name = " pastebin-static ";
        src = gitignoreSource ./../project_templates/pastebin-go/assets;


        installPhase = ''
          mkdir -p $out
          cp -r dist/* $out
        '';
        buildCommands = [ "npm run build" ];
      };
    };
}
