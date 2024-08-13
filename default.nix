{ stdenvNoCC
, lib
, makeWrapper
, abcde # CD ripper
, cdrkit # cdrecord, mkisofs, etc.
, lame # Audio encoder.
}:
let
  path = lib.makeBinPath [
    abcde
    cdrkit
    lame
  ];
in
stdenvNoCC.mkDerivation {
  pname = "audiorc";
  version = "git";
  src = ./.;

  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p "$out/bin" "$out/wrapped" "$out/etc"

    for file in etc/*; do
      install -m 0444 "$file" "$out/etc"
    done

    for file in bin/*; do
      install -m 0555 "$file" "$out/wrapped"

      makeWrapper \
        "$out/wrapped/$(basename "$file")" \
        "$out/bin/$(basename "$file")" \
        --prefix PATH : "${path}"
    done
  '';

}
