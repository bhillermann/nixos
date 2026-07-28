{
  lib,
  pkgs,
  stdenv,
  ...
}:

stdenv.mkDerivation rec {
  pname = "gsd-browser";
  version = "0.2.1";

  src = pkgs.fetchurl {
    url = "https://github.com/open-gsd/gsd-browser/releases/download/v${version}/gsd-browser-linux-x64";
    hash = lib.fakeHash; # first build prints the real one
  };

  dontUnpack = true; # single raw binary, nothing to extract

  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    makeWrapper
  ];

  # Libraries the ELF may link against; autoPatchelf resolves from these.
  buildInputs = with pkgs; [
    stdenv.cc.cc.lib # libgcc_s / libstdc++
    openssl
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${src} $out/bin/gsd-browser
    wrapProgram $out/bin/gsd-browser \
      --set-default GSD_BROWSER_BROWSER_PATH ${pkgs.chromium}/bin/chromium
    runHook postInstall
  '';

  meta = {
    description = "Native browser automation CLI for AI agents via CDP (prebuilt release binary)";
    homepage = "https://github.com/open-gsd/gsd-browser";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "gsd-browser";
    platforms = [ "x86_64-linux" ];
  };
}
