#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${1:-$(curl -s https://registry.npmjs.org/gsd-pi/latest | jq -r .version)}"

URL="https://registry.npmjs.org/gsd-pi/-/gsd-pi-${VERSION}.tgz"
SRC_HASH=$(nix store prefetch-file --json "$URL" | jq -r .hash)

# Reset node_modules hash to fakeHash; bump version + src hash.
sed -i \
  -e "s|version = \".*\";|version = \"${VERSION}\";|" \
  -e "0,/hash = \"sha256-[^\"]*\";/s||hash = \"${SRC_HASH}\";|" \
  -e "s|outputHash = \"sha256-[^\"]*\";|outputHash = \"${lib_fakeHash:-sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=}\";|" \
  "$SCRIPT_DIR/default.nix"

echo "Bumped to ${VERSION}. Now run nixos-rebuild once; copy the 'got:' hash"
echo "into outputHash for the 'prepared' FOD, then rebuild for real."