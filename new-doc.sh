#!/usr/bin/env bash
# Scaffold a new document directory under _source/ with a random password.
# Usage: ./new-doc.sh <doc-name>

set -euo pipefail

cd "$(dirname "$0")"

if [ $# -ne 1 ]; then
  echo "usage: $0 <doc-name>" >&2
  exit 1
fi

doc_name="$1"
if [[ ! "$doc_name" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "error: doc-name must be alphanumerics, dot, underscore, or hyphen only" >&2
  exit 1
fi

dir="_source/$doc_name"
if [ -e "$dir" ]; then
  echo "error: $dir already exists" >&2
  exit 1
fi

mkdir -p "$dir"
password="$(openssl rand -base64 12 | tr -d '/+=' | cut -c1-14)"
printf '%s\n' "$password" > "$dir/.password"
chmod 600 "$dir/.password"

cat <<EOF
Created: $dir/
Password: $password
URL (after push): https://speedkills300-png.github.io/secure-docs/$doc_name/

Next steps:
  1. Place HTML and assets under $dir/
  2. ./encrypt.sh
  3. git add docs && git commit -m "add: $doc_name" && git push
EOF
