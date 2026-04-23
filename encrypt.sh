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
    [ "$rel" = ".password" ] && continue
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
