{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in with pkgs; rec {
        # Development environment
        devShell = mkShell {
          nativeBuildInputs = [
            surfer
            gnumake
            python3
            python313Packages.cocotb
            python313Packages.pytest
            python313Packages.numpy
            verilator
            zlib
          ];
        };

        # packages.app = (...)
        # defaultPackage = packages.app;
      }
    );
}
