#!/bin/zsh
# Rigenera docs/ (GitHub Pages) dai testi legali dell'app.
set -e
cd "$(dirname "$0")/.."
TMP=$(mktemp -d)
# swiftc accetta codice a livello globale solo in un file chiamato main.swift.
cp scripts/make_legal_pages.swift "$TMP/main.swift"
swiftc -O Sources/Models/Legal.swift Sources/Models/LegalEN.swift Sources/Models/LegalIT.swift "$TMP/main.swift" -o "$TMP/genlegal"
"$TMP/genlegal" docs
rm -rf "$TMP"
