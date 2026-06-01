#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NAME="gsd-pi"
NPM_REGISTRY="https://registry.npmjs.org"

# Get latest version if not specified
if [ $# -eq 0 ]; then
  VERSION=$(curl -s "$NPM_REGISTRY/$PACKAGE_NAME/latest" | jq -r '.version')
  echo "No version specified, using latest: $VERSION"
else
  VERSION="$1"
fi

echo "Updating $PACKAGE_NAME to v$VERSION..."

# Fetch and unpack tarball
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

echo "Fetching tarball..."
TARBALL_URL="$NPM_REGISTRY/$PACKAGE_NAME/-/$PACKAGE_NAME-$VERSION.tgz"
curl -sL "$TARBALL_URL" | tar xz -C "$WORK_DIR"

# Generate lock file
echo "Generating package-lock.json..."
cd "$WORK_DIR/package"
npm install --package-lock-only --ignore-scripts --silent

# Get tarball hash
echo "Computing tarball hash..."
TARBALL_HASH=$(nix-prefetch-url "$TARBALL_URL" 2>/dev/null)

# Get npm deps hash
echo "Computing npm deps hash..."
NPM_DEPS_HASH=$(nix run nixpkgs#prefetch-npm-deps -- "$WORK_DIR/package/package-lock.json" 2>/dev/null)

# Copy lock file
cp "$WORK_DIR/package/package-lock.json" "$SCRIPT_DIR/package-lock.json"
echo "Copied package-lock.json"

# Update default.nix
sed -i \
  -e "s|version = \".*\";|version = \"$VERSION\";|" \
  -e "s|hash = \"sha256:.*\";|hash = \"sha256:$TARBALL_HASH\";|" \
  -e "s|npmDepsHash = \".*\";|npmDepsHash = \"$NPM_DEPS_HASH\";|" \
  "$SCRIPT_DIR/default.nix"

echo ""
echo "Done! Updated $SCRIPT_DIR/default.nix:"
echo "  version:      $VERSION"
echo "  tarball hash: sha256:$TARBALL_HASH"
echo "  deps hash:    $NPM_DEPS_HASH"
echo ""
echo "Next steps:"
echo "  cd ~/.nixos && git add packages/gsd-2/ && git commit -m 'packages/gsd-2: update to v$VERSION'"
echo "  sudo nixos-rebuild switch"