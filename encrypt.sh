#!/usr/bin/env bash
# Encrypt every document under _source/ using its per-document password.
#
# Layout:
#   _source/<doc-name>/.password  ← password for that document (gitignored)
#   _source/<doc-name>/<files>    ← HTML and assets
# Output:
#   docs/<doc-name>/              ← encrypted HTML + verbatim assets

set -euo pipefail

cd "$(dirname "$0")"

if [ ! -d _source ]; then
  echo "error: _source/ directory not found" >&2
  exit 1
fi

rm -rf docs
mkdir -p docs

shopt -s nullglob
docs_found=0

for doc_dir in _source/*/; do
  doc_name="$(basename "$doc_dir")"
  pw_file="$doc_dir/.password"
  if [ ! -f "$pw_file" ]; then
    echo "error: $pw_file not found. Run ./new-doc.sh $doc_name to generate one." >&2
    exit 1
  fi
  password="$(tr -d '\r\n' < "$pw_file")"
  if [ -z "$password" ]; then
    echo "error: $pw_file is empty" >&2
    exit 1
  fi

  # Persistent per-document salt so that share URLs remain stable across re-encryptions.
  salt_file="$doc_dir/.salt"
  if [ ! -f "$salt_file" ]; then
    openssl rand -hex 16 > "$salt_file"
    chmod 600 "$salt_file"
  fi
  salt="$(tr -d '\r\n' < "$salt_file")"
  if [ -z "$salt" ]; then
    echo "error: $salt_file is empty" >&2
    exit 1
  fi

  echo ">> encrypting $doc_name"
  outdir="docs/$doc_name"
  mkdir -p "$outdir"
  docs_found=$((docs_found + 1))

  while IFS= read -r -d '' html; do
    rel="${html#$doc_dir}"
    html_outdir="$outdir/$(dirname "$rel")"
    mkdir -p "$html_outdir"
    npx -y staticrypt@3 "$html" \
      --password "$password" \
      --salt "$salt" \
      --short \
      --template-title "Protected Document" \
      --template-instructions "Enter the password to view this document." \
      --template-button "View" \
      -d "$html_outdir" >/dev/null
    base="$(basename "$html")"
    target="$html_outdir/$(basename "$rel")"
    if [ -f "$html_outdir/$base" ] && [ "$html_outdir/$base" != "$target" ]; then
      mv "$html_outdir/$base" "$target"
    fi
  done < <(find "$doc_dir" -type f -name '*.html' -print0)

  while IFS= read -r -d '' f; do
    rel="${f#$doc_dir}"
    # Local-only files that must NOT be published.
    [ "$rel" = ".password" ] && continue
    [ "$rel" = ".salt" ] && continue
    [ "$rel" = "share-url.txt" ] && continue
    [[ "$rel" == *.pdf ]] && continue
    dest="$outdir/$rel"
    mkdir -p "$(dirname "$dest")"
    cp "$f" "$dest"
  done < <(find "$doc_dir" -type f ! -name '*.html' -print0)
done

if [ "$docs_found" -eq 0 ]; then
  echo "error: no document directories found under _source/" >&2
  exit 1
fi

echo "Done. Encrypted $docs_found document(s) into docs/"
