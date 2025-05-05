#!/usr/bin/env bash
set -euo pipefail

# Script: appimage2deb.sh
# Description: Convert an AppImage into a Debian package layout for later .deb packaging.

APPIMAGE="${1:-}"
USER_DEPS="${2:-}"

if [[ -z "$APPIMAGE" || ! -f "$APPIMAGE" ]]; then
  echo "Usage: $0 <AppImage> [\"Depends list\"]"
  exit 1
fi

# Derive names and version
PKG_NAME="$(basename "$APPIMAGE" .AppImage)"
# Try to extract version from AppImage metadata or fallback to timestamp
VERSION="$(strings "$APPIMAGE" \
  | grep -m1 -E '^[0-9]+\.[0-9]+(\.[0-9]+)?')"
ARCH="$(dpkg --print-architecture)"

# Prepare workspace
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"

# Extract AppImage (produces squashfs-root/)
chmod +x "$OLDPWD/$APPIMAGE"
"$OLDPWD/$APPIMAGE" --appimage-extract >/dev/null

# Setup package directory structure
OUTPUT_DIR="$OLDPWD/sources"
PKGDIR="$OUTPUT_DIR/${PKG_NAME}_${VERSION}_${ARCH}"
mkdir -p "$PKGDIR/DEBIAN" \
         "$PKGDIR/opt/$PKG_NAME" \
         "$PKGDIR/usr/bin"

# Move payload under /opt
mv squashfs-root/* "$PKGDIR/opt/$PKG_NAME/"

# Create launch symlink
ln -s "/opt/$PKG_NAME/AppRun" \
      "$PKGDIR/usr/bin/$PKG_NAME"



# Write control file
cat > "$PKGDIR/DEBIAN/control" <<EOF
Package: $PKG_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Depends: ${USER_DEPS:-}
Maintainer: $(whoami) <$(whoami)@$(hostname)>
Description: Auto-converted AppImage ($PKG_NAME) to Debian package layout
EOF

# Create .desktop file
mkdir -p "$PKGDIR/usr/share/applications/"
cat > "$PKGDIR/usr/share/applications/${PKG_NAME}.desktop" <<EOF
[Desktop Entry]
Name=$PKG_NAME
Exec=/usr/bin/$PKG_NAME
Icon=/opt/$PKG_NAME/net.davidotek.pupgui2.png
Type=Application
Categories=Utility;
EOF


# Output notice
echo "Prepared Debian package layout at: $PKGDIR"
echo "You can now run: dpkg-deb --build \"$PKGDIR\""
