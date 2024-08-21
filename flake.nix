{
  description = "Peter's Media Configuration and Scripts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      # List of supported systems:
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "armv7l-linux"
        "i686-linux"
      ];

      # Function to generate a set based on supported systems:
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Attribute set of nixpkgs for each system:
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system}; in {
          mediarc = pkgs.callPackage ./. { };
        });

      overlays.mediarc = final: prev: {
        pjones = (prev.pjones or { }) // {
          mediarc = self.packages.${prev.system}.mediarc;
        };
      };

      devShells = forAllSystems (system: {
        default = nixpkgsFor.${system}.mkShell {
          inputsFrom = builtins.attrValues self.packages.${system};
        };
      });
    };
}
