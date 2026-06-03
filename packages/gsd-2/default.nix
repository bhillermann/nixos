{ lib, pkgs, stdenv, ... }:

let
  pname = "gsd-pi";
  # Get current version: curl -s https://registry.npmjs.org/@opengsd/gsd-pi/latest | jq -r .version
  version = "1.1.1";

  # Scoped package @opengsd/gsd-pi — tarball filename omits the scope.
  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@opengsd/gsd-pi/-/gsd-pi-${version}.tgz";
    hash = "sha256-3QCpiA1tvFJb35GLShSmcbyY/cnGOJIgfwf3G7ucUII=";
  };

  prepared = stdenv.mkDerivation {
    name = "${pname}-${version}-prepared";
    inherit src;

    nativeBuildInputs = [ pkgs.nodejs_22 pkgs.cacert ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      export HOME="$TMPDIR"
      npm install --ignore-scripts --omit=dev --no-audit --no-fund

      # 1.1.1 dropped workspace metadata and relies on loader.js linking
      # packages/@gsd/* into node_modules/@gsd at runtime — but the store is
      # read-only, so create those links now, at build time.
      mkdir -p node_modules/@gsd
      for d in packages/*/; do
        name=$(${pkgs.jq}/bin/jq -r '.name // empty' "$d/package.json")
        case "$name" in
          @gsd/*)
            target="''${name#@gsd/}"
            ln -sfn "../../$d" "node_modules/@gsd/$target"
            ;;
        esac
      done

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r . "$out/"
      runHook postInstall
    '';
    dontFixup = true;

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-/SZ/cb0yehm+7UkvMfxQfcTDlJ3s+lL6cuHMcsvIyng=";
  };
in stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    makeWrapper ${pkgs.nodejs_22}/bin/node "$out/bin/gsd" \
      --add-flags "${prepared}/dist/loader.js"
    runHook postInstall
  '';

  meta = with lib; {
    description = "GSD Pi — autonomous coding agent (open-gsd)";
    homepage = "https://github.com/open-gsd/gsd-pi";
    license = licenses.mit;
    mainProgram = "gsd";
  };
}
