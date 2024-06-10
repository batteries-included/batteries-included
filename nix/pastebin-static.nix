{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      inherit (inputs.gitignore.lib) gitignoreSource;

      inherit (pkgs) nodejs;
      npmlock2nix = pkgs.callPackages inputs.npmlock2nix { };
      version = "0.12.4";
    in
    {
      packages.pastebin-static = npmlock2nix.v2.build {
        inherit nodejs version;
        pname = "pastebin";
        name = " pastebin-static ";
        src = gitignoreSource ./../pastebin-go/assets;

        installPhase = ''
          mkdir -p $out
          cp -r dist/* $out
        '';
        buildCommands = [ "npm run build" ];
      };
    };
}
