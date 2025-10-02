#!/usr/bin/env bash
set -euo pipefail

# --- Konfiguration / Defaults ---
# Projekt-Root = Ordner über "scripts/"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
STAGE="$DIST/ReleaseDisk"

# 1. Argument: Pfad zur .app in dist (optional)
#    Wenn nicht angegeben, wird die erste *.app in dist genommen.
APP_PATH_DEFAULT=$(ls "$DIST"/*.app 2>/dev/null | head -n 1 || true)
APP_PATH="${1:-${APP_PATH_DEFAULT}}"

if [[ -z "${APP_PATH}" || ! -d "${APP_PATH}" ]]; then
  echo "❌ Keine .app in $DIST gefunden. Exportiere deine App nach dist/ und rufe dann:"
  echo "   scripts/make_dmg.sh \"dist/DeineApp.app\" [VERSION]"
  exit 1
fi

# App-Name ohne .app
APP_NAME="$(basename "$APP_PATH" .app)"

# 2. Argument: Version (optional)
#    Wenn nicht angegeben, wird versucht, sie aus Info.plist zu lesen.
read_version_plist() {
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
    "$APP_PATH/Contents/Info.plist" 2>/dev/null || true
}
VERSION="${2:-$(read_version_plist)}"
VERSION="${VERSION:-0.1.0}"

DMG_PATH="$DIST/${APP_NAME}-${VERSION}.dmg"

echo "🔧 Erzeuge DMG"
echo "   App:      $APP_PATH"
echo "   Version:  $VERSION"
echo "   Ausgabe:  $DMG_PATH"
echo

# --- Stage vorbereiten ---
rm -rf "$STAGE"
mkdir -p "$STAGE"

# App in Stage kopieren
rsync -a --delete "$APP_PATH" "$STAGE/"

# Applications-Link hinzufügen (Drag&Drop-Install)
ln -s /Applications "$STAGE/Applications" 2>/dev/null || true

# --- DMG bauen ---
# UDZO = komprimierte DMG; UDBZ wäre bzip2 (kleiner, etwas langsamer).
/usr/bin/hdiutil create \
  -volname "${APP_NAME} ${VERSION}" \
  -srcfolder "$STAGE" \
  -ov -format UDZO "$DMG_PATH" > /dev/null

# --- Aufräumen (Stage behalten? -> auskommentieren, wenn du reinschauen willst)
rm -rf "$STAGE"

echo "✅ Fertig: $DMG_PATH"