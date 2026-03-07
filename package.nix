# package.nix - Build micromort as an installable R package derivation
#
# Used by push_to_cachix.sh to build and push to johngavin cachix.
# Uses same rstats-on-nix pin as default.nix (2026-01-05).
#
# Usage:
#   nix-build package.nix --no-out-link
#   # Push ONLY this package (not deps!) to cachix:
#   nix-build package.nix --no-out-link | cachix push johngavin

let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2026-01-05.tar.gz") {};

  micromort = pkgs.rPackages.buildRPackage {
    name = "micromort";
    src = ./.;

    # Imports from DESCRIPTION
    propagatedBuildInputs = with pkgs.rPackages; [
      arrow
      checkmate
      cli
      dplyr
      ggplot2
      scales
      tibble
    ];
  };

in micromort
