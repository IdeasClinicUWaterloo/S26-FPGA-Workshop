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
            gnumake
            python3
            python313Packages.cocotb
            verilator
            zlib
          ];
        };

        # packages.app = (...)
        # defaultPackage = packages.app;
      }
    );
}
