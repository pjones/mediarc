let
  overlay =
    (self: super: {
      vlc = super.vlc.override {
        libbluray = super.libbluray.override {
          withAACS = true;
          withBDplus = true;
        };
      };
    });

  pkgs = import <nixpkgs> {
    overlays = [ overlay ];
  };
in
pkgs.mkShell {
  buildInputs = [ pkgs.vlc ];
}
