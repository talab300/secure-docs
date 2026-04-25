# secure-docs

Password-protected documents published via GitHub Pages.

The repository is public, but every document is encrypted client-side with
[StatiCrypt](https://github.com/robinmoisson/staticrypt) (AES-256). Each
document has its own password — share only the password for the document you
want a viewer to access.

## Layout

```
_source/                       # Plaintext originals — gitignored, local only
  <doc-name>/
    .password                  # Per-document password
    index.html
    <other assets>
docs/                          # Encrypted output — committed and served by Pages
  <doc-name>/
    index.html                 # Encrypted
    <other assets>             # Copied verbatim
encrypt.sh                     # Re-encrypt every document
new-doc.sh <name>              # Scaffold a new document with a random password
```

## Add a new document

```sh
./new-doc.sh 20260601-some-topic
# → prints the generated password
# Place HTML and assets under _source/20260601-some-topic/
./encrypt.sh
git add docs && git commit -m "add: 20260601-some-topic" && git push
```

URL: `https://talab300.github.io/secure-docs/20260601-some-topic/`

## Update an existing document

1. Edit files under `_source/<doc-name>/`.
2. `./encrypt.sh`
3. `git add docs && git commit -m "update: <doc-name>" && git push`

## Change a document's password

1. Overwrite `_source/<doc-name>/.password` with the new password.
2. `./encrypt.sh`
3. `git add docs && git commit -m "rotate: <doc-name>" && git push`
4. Distribute the new password to viewers.

## Remove a document

1. `rm -rf _source/<doc-name>`
2. `./encrypt.sh`  (clears `docs/` and re-emits remaining docs)
3. `git add -A docs && git commit -m "remove: <doc-name>" && git push`
