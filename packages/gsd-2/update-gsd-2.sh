#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="@opengsd/gsd-pi"
NAME="gsd-pi"

VERSION="${1:-$(curl -s "https://registry.npmjs.org/${PKG}/latest" | jq -r .version)}"
URL="https://registry.npmjs.org/${PKG}/-/${NAME}-${VERSION}.tgz"

echo "Updating ${PKG} to v${VERSION}..."
SRC_HASH=$(nix store prefetch-file --json "$URL" | jq -r .hash)

# Bump version + src hash; reset the FOD outputHash so the next build reveals it.
sed -i -E \
  -e "s|version = \"[^\"]*\";|version = \"${VERSION}\";|" \
  -e "s|url = \"https://registry.npmjs.org/@opengsd/gsd-pi/-/gsd-pi-[^\"]*\.tgz\";|url = \"${URL}\";|" \
  -e "0,/hash = (lib.fakeHash\|\"sha256-[^\"]*\");/s||hash = \"${SRC_HASH}\";|" \
  -e "s|outputHash = [^;]+;|outputHash = lib.fakeHash;|" \
  "$SCRIPT_DIR/default.nix"

echo ""
echo "Set version=${VERSION}, src hash=${SRC_HASH}, reset outputHash to fakeHash."
echo "Now: nixos-rebuild once, copy the FOD 'got:' hash into outputHash, rebuild for real."#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="@opengsd/gsd-pi"
NAME="gsd-pi"

VERSION="${1:-$(curl -s "https://registry.npmjs.org/${PKG}/latest" | jq -r .version)}"
URL="https://registry.npmjs.org/${PKG}/-/${NAME}-${VERSION}.tgz"

echo "Updating ${PKG} to v${VERSION}..."
SRC_HASH=$(nix store prefetch-file --json "$URL" | jq -r .hash)

# Bump version + src hash; reset the FOD outputHash so the next build reveals it.
sed -i -E \
  -e "s|version = \"[^\"]*\";|version = \"${VERSION}\";|" \
  -e "s|url = \"https://registry.npmjs.org/@opengsd/gsd-pi/-/gsd-pi-[^\"]*\.tgz\";|url = \"${URL}\";|" \
  -e "0,/hash = (lib.fakeHash\|\"sha256-[^\"]*\");/s||hash = \"${SRC_HASH}\";|" \
  -e "s|outputHash = [^;]+;|outputHash = lib.fakeHash;|" \
  "$SCRIPT_DIR/default.nix"

echo ""
echo "Set version=${VERSION}, src hash=${SRC_HASH}, reset outputHash to fakeHash."
echo "Now: nixos-rebuild once, copy the FOD 'got:' hash into outputHash, rebuild for real."