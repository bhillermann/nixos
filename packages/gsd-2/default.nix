{ lib, pkgs, stdenv, ... }:

let
  pname = "gsd-pi";
  # Get current version: curl -s https://registry.npmjs.org/@opengsd/gsd-pi/latest | jq -r .version
  version = "1.2.0";

  # Scoped package @opengsd/gsd-pi — tarball filename omits the scope.
  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@opengsd/gsd-pi/-/gsd-pi-${version}.tgz";
    hash = "sha256-vIURB5RZbslnG8ULGb9AlcryILMejrgWYqQjEdIlSpk=";
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

      # 1.1.1 dropped workspace metadata; link every bundled workspace package
      # into node_modules by its real (scoped) name. Packages span multiple
      # scopes (@gsd/*, @opengsd/*), so derive the scope from package.json
      # rather than hardcoding it.
      for d in packages/*/; do
        name=$(${pkgs.jq}/bin/jq -r '.name // empty' "$d/package.json")
        [ -n "$name" ] || continue
        scope=$(dirname "$name")          # e.g. @opengsd  (or "." if unscoped)
        mkdir -p "node_modules/$scope"
        ln -sfn "$(realpath -m --relative-to="node_modules/$scope" "$d")" "node_modules/$name"
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
    outputHash = "sha256-gL8Iiw85qqBCoyUbdnAk0N2+EHQisMZxOxuUHJwEwl4=";
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
    makeWrapper ${pkgs.nodejs_22}/bin/node "$out/bin/gsd-mcp-server" \
      --add-flags "${prepared}/packages/mcp-server/dist/cli.js"
    runHook postInstall
  '';

  meta = with lib; {
    description = "GSD Pi — autonomous coding agent (open-gsd)";
    homepage = "https://github.com/open-gsd/gsd-pi";
    license = licenses.mit;
    mainProgram = "gsd";
  };
}
