{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }: {
        systems = [
          "x86_64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];

        perSystem =
          { pkgs, system, ... }:
          {
            packages.mediarc = pkgs.callPackage ./. { };

            devShells.default = pkgs.mkShell {
              NIX_PATH = "nixpkgs=${pkgs.path}";
              inputsFrom = builtins.attrValues self.packages.${system};

              nativeBuildInputs = with pkgs; [
                beets
              ];
            };
          };
      }
    );
}
