#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "🔨 Compilation de TradApp..."
swift build -c release

echo "📦 Création du bundle..."
rm -rf TradApp.app
mkdir -p TradApp.app/Contents/MacOS TradApp.app/Contents/Resources
cp .build/release/TradApp TradApp.app/Contents/MacOS/
cp Resources/Info.plist TradApp.app/Contents/
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns TradApp.app/Contents/Resources/

echo "✍️  Signature..."
xattr -cr TradApp.app
codesign --force --deep --sign - TradApp.app

echo "🚀 Installation dans /Applications..."
rm -rf /Applications/TradApp.app
cp -R TradApp.app /Applications/

# Effacer l'ancienne entrée TCC (nécessaire car la signature change à chaque build)
echo "🔐 Réinitialisation des permissions accessibilité..."
echo "   (entrez votre mot de passe macOS si demandé)"
sudo tccutil reset Accessibility personal.tradapp 2>/dev/null || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TradApp installé dans /Applications"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
open /Applications/TradApp.app
