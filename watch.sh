#!/bin/bash
# watch.sh - Surveille les modifications Swift et reconstruit TradApp automatiquement

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_DIR="$SCRIPT_DIR/Sources"
SENTINEL="/tmp/trad_watch_sentinel"

touch "$SENTINEL"

cleanup() {
    rm -f "$SENTINEL"
    echo ""
    echo "⏹  Surveillance arrêtée."
    exit 0
}

trap cleanup INT TERM

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "👀  TradApp – Surveillance active"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Modifie un fichier Swift pour déclencher"
echo "   un rebuild automatique."
echo "   Ctrl+C pour arrêter."
echo ""

while true; do
    CHANGED=$(find "$SOURCES_DIR" -name "*.swift" -newer "$SENTINEL" 2>/dev/null)

    if [ -n "$CHANGED" ]; then
        sleep 0.5   # Debounce : attendre d'éventuelles autres sauvegardes simultanées
        touch "$SENTINEL"

        echo "📝 Modifications détectées :"
        echo "$CHANGED" | while IFS= read -r f; do
            echo "   • $(basename "$f")"
        done
        echo ""

        # Fermer l'app si elle tourne
        pkill -f "TradApp.app/Contents/MacOS/TradApp" 2>/dev/null || true
        sleep 0.3

        echo "⚙️  Reconstruction en cours..."
        echo ""
        if bash "$SCRIPT_DIR/build.sh"; then
            echo ""
            echo "✅ Prêt !"
        else
            echo ""
            echo "❌ Erreur de compilation — corrige les erreurs et sauvegarde à nouveau."
        fi

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "👀  En attente de modifications..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi

    sleep 1
done
