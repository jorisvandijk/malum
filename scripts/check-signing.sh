#!/bin/bash
# Signs a copy of the built app the way Malum signs itself, with a throwaway key file and the
# bundled rcodesign, then checks the signature and its designated requirement with codesign.
#
# usage: scripts/check-signing.sh [app]   (default: the app in build)
set -euo pipefail

cd "$(dirname "$0")/.."

app="${1:-$(ls -d build/*.app)}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cat > "$work/openssl.cnf" <<CONFIG
[req]
distinguished_name = dn
prompt = no

[dn]
CN = Signing check

[ext]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
CONFIG
openssl req -x509 -newkey rsa:2048 -sha256 -days 1 -nodes -keyout "$work/key.pem" -out "$work/certificate.pem" \
    -config "$work/openssl.cnf" -extensions ext 2>/dev/null
cat "$work/key.pem" "$work/certificate.pem" > "$work/identity.pem"
leaf="$(openssl x509 -in "$work/certificate.pem" -noout -fingerprint -sha1 | sed 's/.*=//; s/://g')"
# rcodesign takes a single compiled requirement, which becomes the designated one.
csreq -r="certificate leaf = H\"$leaf\"" -b "$work/requirement.bin"

cp -R "$app" "$work/Check.app"
"$app/Contents/Helpers/rcodesign" sign --pem-file "$work/identity.pem" \
    --code-requirements-path "$work/requirement.bin" \
    --timestamp-url none "$work/Check.app"
codesign --verify --strict --verbose=2 "$work/Check.app"
codesign --verify --strict --test-requirement="=certificate leaf = H\"$leaf\"" "$work/Check.app"
codesign -d -r- "$work/Check.app" 2>&1 | tee "$work/requirement.txt"
grep -q "certificate leaf = H\"$(printf '%s' "$leaf" | tr 'A-F' 'a-f')\"" "$work/requirement.txt" \
    || grep -qi "certificate leaf = H\"$leaf\"" "$work/requirement.txt"
echo "[info] rcodesign signs with a key file and a stable designated requirement"
