#!/usr/bin/env bash
set -euo pipefail

# GitHub repository owner and name
OWNER="DavidoTek"
REPO="ProtonUp-Qt"

# GitHub API URL for the latest release
API_URL="https://api.github.com/repos/${OWNER}/${REPO}/releases/latest"

# Temporary file for storing JSON response
TMP_JSON="$(mktemp)"

# Fetch latest release metadata :contentReference[oaicite:3]{index=3}
curl -fsSL "$API_URL" -o "$TMP_JSON"

# Extract AppImage download URL :contentReference[oaicite:4]{index=4}
ASSET_URL=$(jq -r '.assets[] | select(.name | endswith(".AppImage")) | .browser_download_url' "$TMP_JSON")

# Clean up JSON file
rm -f "$TMP_JSON"

# Download the AppImage asset and save to current directory :contentReference[oaicite:5]{index=5}
wget  "$ASSET_URL"

# Make the AppImage executable


#echo "Downloaded and made executable: ProtonUp-Qt.AppImage"
