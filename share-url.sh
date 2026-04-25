#!/usr/bin/env bash
# Generate an auto-decrypt share URL for an encrypted document.
# Usage: ./share-url.sh <doc-name>
#
# The URL embeds the hashed password in the fragment (#staticrypt_pwd=...),
# which means it stays client-side (never sent to the server). Anyone with
# the URL can view the document — treat the URL itself as the access token.

set -euo pipefail

cd "$(dirname "$0")"

if [ $# -ne 1 ]; then
  echo "usage: $0 <doc-name>" >&2
  exit 1
fi

doc_name="$1"
doc_dir="_source/$doc_name"
pw_file="$doc_dir/.password"
salt_file="$doc_dir/.salt"

if [ ! -d "$doc_dir" ]; then
  echo "error: $doc_dir not found" >&2
  exit 1
fi
if [ ! -f "$pw_file" ]; then
  echo "error: $pw_file not found" >&2
  exit 1
fi
if [ ! -f "$salt_file" ]; then
  echo "error: $salt_file not found. Run ./encrypt.sh first to generate the salt." >&2
  exit 1
fi

password="$(tr -d '\r\n' < "$pw_file")"
salt="$(tr -d '\r\n' < "$salt_file")"

# Determine the public URL for this document.
# Override via env var SECURE_DOCS_BASE_URL if needed.
base_url="${SECURE_DOCS_BASE_URL:-https://talab300.github.io/secure-docs}"
public_url="$base_url/$doc_name/"

# Use staticrypt's --share to compute the URL with hashed password.
# We encrypt a temporary dummy file just to harvest the share URL output.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
echo '<html><body></body></html>' > "$tmp/dummy.html"

share_url="$(
  npx -y staticrypt@3 "$tmp/dummy.html" \
    --password "$password" \
    --salt "$salt" \
    --short \
    --share "$public_url" \
    -d "$tmp/out" 2>&1 \
  | grep -oE 'https?://[^[:space:]]+#staticrypt_pwd=[a-f0-9]+' \
  | head -1
)"

if [ -z "$share_url" ]; then
  echo "error: failed to generate share URL" >&2
  exit 1
fi

# Persist the share URL alongside .password / .salt (gitignored via _source/).
out_file="$doc_dir/share-url.txt"
printf '%s\n' "$share_url" > "$out_file"
chmod 600 "$out_file"

echo "$share_url"
