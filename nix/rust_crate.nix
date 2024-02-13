{ pname, crane, pkgs, src, nativeBuildInputs ? [ ], buildInputs ? [ ], cargoExtraArgs ? "", ... }:

let
  craneLib = (crane.mkLib pkgs).overrideToolchain pkgs.rust-bin.nightly.latest.default;
  frameworks = pkgs.darwin.apple_sdk.frameworks;

  darwinOnlyTools = [
    frameworks.Security
    frameworks.CoreServices
    frameworks.CoreFoundation
    frameworks.Foundation
  ];

  # Common arguments can be set here to avoid repeating them later
  commonArgs = {
    inherit pname cargoExtraArgs;
    src = src;
    nativeBuildInputs = with pkgs; [ pkg-config ] ++ nativeBuildInputs;
    buildInputs = with pkgs; [ openssl ]
      ++ buildInputs
      ++ lib.optionals pkgs.stdenv.isDarwin darwinOnlyTools
      ++ lib.optionals pkgs.stdenv.isLinux [ ];
  };

  # Build *just* the cargo dependencies, so we can reuse
  # all of that work (e.g. via cachix) when running in CI
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  cargo-crate = craneLib.buildPackage (commonArgs // {
    inherit cargoArtifacts;
    doCheck = false;
    meta.mainProgram = "${pname}";
  });
in

{
  checks = {

    "${pname}-crate-build" = cargo-crate;

    # Run clippy (and deny all warnings) on the crate source,
    # again, resuing the dependency artifacts from above.
    #
    # Note that this is done as a separate derivation so that
    # we can block the CI if there are issues here, but not
    # prevent downstream consumers from building our crate by itself.
    "${pname}-crate-clippy" = craneLib.cargoClippy (commonArgs // {
      inherit cargoArtifacts;
      cargoClippyExtraArgs = "--all-targets -- --deny warnings";
    });

    "${pname}-crate-doc" = craneLib.cargoDoc (commonArgs // {
      inherit cargoArtifacts;
    });

    "${pname}-crate-fmt" = craneLib.cargoFmt {
      inherit src;
    };

    # # Audit dependencies
    # Audit is disabled until NixOS/nixpkgs#288064 is resolved
    #
    # "${pname}-crate-audit" = craneLib.cargoAudit {
    #   inherit src advisory-db pname;

    #   cargoAuditExtraArgs = "--ignore RUSTSEC-2023-0071";
    # };

    "${pname}-crate-test" = craneLib.cargoNextest (commonArgs // {
      inherit cargoArtifacts;
      partitions = 1;
      partitionType = "count";
      cargoNextestExtraArgs = "--all-targets";
    });
  };

  packages = {
    "${pname}" = cargo-crate;
  };
}
