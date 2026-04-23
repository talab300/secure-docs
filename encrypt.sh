#!/usr/bin/env bash
# Encrypt every HTML under _source/ with StatiCrypt and emit to docs/.
# Non-HTML assets are copied verbatim. Password is read from the env var
# STATICRYPT_PASSWORD or, if absent, from a local .password file (gitignored).

set -euo pipefail

cd "$(dirname "$0")"

if [ -z "${STATICRYPT_PASSWORD:-}" ]; then
  if [ -f .password ]; then
    STATICRYPT_PASSWORD="$(tr -d '\r\n' < .password)"
  else
    echo "error: set STATICRYPT_PASSWORD env var, or create a .password file" >&2
    exit 1
  fi
fi

if [ ! -d _source ]; then
  echo "error: _source/ directory not found" >&2
  exit 1
fi

rm -rf docs
mkdir -p docs

while IFS= read -r -d '' html; do
  rel="${html#_source/}"
  outdir="docs/$(dirname "$rel")"
  mkdir -p "$outdir"
  npx -y staticrypt@3 "$html" \
    --password "$STATICRYPT_PASSWORD" \
    --short \
    --template-title "Protected Document" \
    --template-instructions "Enter the password to view this document." \
    --template-button "View" \
    -d "$outdir" >/dev/null
  base="$(basename "$html")"
  target="$outdir/$(basename "$rel")"
  if [ -f "$outdir/$base" ] && [ "$outdir/$base" != "$target" ]; then
    mv "$outdir/$base" "$target"
  fi
done < <(find _source -type f -name '*.html' -print0)

# Copy non-HTML assets, preserving directory layout
while IFS= read -r -d '' f; do
  rel="${f#_source/}"
  dest="docs/$rel"
  mkdir -p "$(dirname "$dest")"
  cp "$f" "$dest"
done < <(find _source -type f ! -name '*.html' -print0)

echo "Done. Encrypted output in docs/"
