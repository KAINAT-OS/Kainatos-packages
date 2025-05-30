#!/usr/bin/env bash
set -euo pipefail

# Script: appimage2deb.sh
# Description: Convert an AppImage into a Debian package layout for later .deb packaging.
#install depends

APPIMAGE="${1:-}"
USER_DEPS="${2:-}"

if [[ -z "$APPIMAGE" || ! -f "$APPIMAGE" ]]; then
  echo "Usage: $0 <AppImage> [\"Depends list\"]"
  exit 1
fi

# Derive names and version
Appimg_Name="$(basename "$APPIMAGE")"
PKG_NAME="$(basename "$APPIMAGE" .AppImage)"
# Try to extract version from AppImage metadata or fallback to timestamp
VERSION="$( curl -s https://api.github.com/repos/DavidoTek/ProtonUp-Qt/tags | \
jq -r 'first(.[].name | select(test("^v[0-9]")))'
)"
VERSION="$(echo $VERSION | cut -c2- )"
ARCH="x86-64"

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
mv squashfs-root/*.png "$PKGDIR/opt/$PKG_NAME/"

# Create launch symlink
mv  "$OLDPWD/$APPIMAGE" \
      "$PKGDIR/usr/bin/$PKG_NAME.AppImage"

chmod +x "$PKGDIR/usr/bin/$PKG_NAME.AppImage"

# Write control file
cat > "$PKGDIR/DEBIAN/control" <<EOF
Package: protonup-qt
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: ${USER_DEPS:-}
Maintainer: $(whoami) <$(whoami)@$(hostname)>
Description: Auto-converted AppImage ($PKG_NAME) to Debian package layout
EOF

# Create .desktop file
mkdir -p "$PKGDIR/usr/share/applications/"
cat > "$PKGDIR/usr/share/applications/${PKG_NAME}.desktop" <<EOF
[Desktop Entry]
Name=$PKG_NAME
Exec=/usr/bin/$PKG_NAME.AppImage
Icon=/opt/$PKG_NAME/net.davidotek.pupgui2.png
Type=Application
Categories=Utility;
EOF


# Output notice
echo "Prepared Debian package layout at: $PKGDIR"
echo "You can now run: dpkg-deb --build \"$PKGDIR\""
