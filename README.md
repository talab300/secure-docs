# secure-docs

Password-protected documents published via GitHub Pages.

The repository is public, but every document is encrypted client-side with
[StatiCrypt](https://github.com/robinmoisson/staticrypt) (AES-256). Only viewers
who know the shared password can read the contents.

## Layout

```
_source/        # Plaintext originals — gitignored, kept locally only
docs/           # Encrypted output — committed and served by GitHub Pages
encrypt.sh      # Local encryption script (run before commit)
.password       # Local password file — gitignored
```

## Adding or updating a document

1. Drop or edit HTML (and assets) under `_source/<doc-name>/`.
2. Run `./encrypt.sh` (uses `STATICRYPT_PASSWORD` env var or `.password` file).
3. Commit and push the regenerated `docs/`.

## Published URL

```
https://speedkills300-png.github.io/secure-docs/<doc-name>/
```

## Changing the password

Update `.password` (or the env var), re-run `./encrypt.sh`, then commit and push.
