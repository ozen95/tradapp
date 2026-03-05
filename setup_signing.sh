#!/bin/bash
# Configure un certificat de signature local pour TradApp.
# À exécuter UNE SEULE FOIS — pas de sudo nécessaire.

set -e

CERT_NAME="TradApp Local"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

echo ""
echo "🔑 Configuration du certificat de signature TradApp..."
echo ""

# Vérifier si le certificat existe déjà
if security find-certificate -c "$CERT_NAME" "$KEYCHAIN" &>/dev/null; then
    echo "✅ Certificat '$CERT_NAME' déjà présent — rien à faire."
    echo ""
    exit 0
fi

# Créer la config OpenSSL
cat > /tmp/tradapp_cert.cfg << 'EOF'
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
x509_extensions    = v3_req

[dn]
CN = TradApp Local

[v3_req]
keyUsage         = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
basicConstraints = critical, CA:false
EOF

# Générer clé + certificat
openssl req -newkey rsa:2048 -nodes \
    -keyout /tmp/tradapp_local.key \
    -x509 -days 3650 \
    -out /tmp/tradapp_local.crt \
    -config /tmp/tradapp_cert.cfg 2>/dev/null

# Packager en PKCS12
openssl pkcs12 -export \
    -out /tmp/tradapp_local.p12 \
    -inkey /tmp/tradapp_local.key \
    -in /tmp/tradapp_local.crt \
    -passout pass: \
    -name "$CERT_NAME" 2>/dev/null

# Importer dans le keychain utilisateur
security import /tmp/tradapp_local.p12 \
    -k "$KEYCHAIN" \
    -P "" \
    -T /usr/bin/codesign \
    -A 2>/dev/null

# Faire confiance au certificat pour la signature de code
security add-trusted-cert \
    -r trustAsRoot \
    -p codeSign \
    -k "$KEYCHAIN" \
    /tmp/tradapp_local.crt

# Nettoyage
rm -f /tmp/tradapp_local.{key,crt,p12} /tmp/tradapp_cert.cfg

echo "✅ Certificat '$CERT_NAME' créé et approuvé."
echo ""
echo "👉 Lance maintenant : bash build.sh"
echo "   macOS pourrait demander d'autoriser l'accès au trousseau → clique 'Toujours autoriser'."
echo ""
