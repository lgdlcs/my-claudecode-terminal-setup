#!/bin/bash
# Fait de VSCode l'app par défaut pour les fichiers texte/code.
# But : ⌘+clic sur un chemin dans Ghostty (qui appelle `open`) ouvre le fichier dans VSCode.
# Revert : ./set-vscode-default-handlers.sh --revert  (repasse sur TextEdit)

set -u

APP="com.microsoft.VSCode"
[ "${1:-}" = "--revert" ] && APP="com.apple.TextEdit"

UTIS=(
  public.plain-text public.text public.source-code public.script public.data
  public.utf8-plain-text public.utf16-plain-text public.delimited-values-text
  public.comma-separated-values-text public.tab-separated-values-text
  public.shell-script public.python-script public.perl-script public.ruby-script
  public.php-script public.json public.yaml public.xml public.html
  public.c-source public.c-header public.c-plus-plus-source public.objective-c-source
  public.assembly-source public.make-source public.patch-file public.log
  com.netscape.javascript-source com.apple.property-list
  net.daringfireball.markdown org.tug.tex dyn.ah62d4rv4ge8043a
)

EXTS=(
  txt text md markdown mdx rst adoc log
  js jsx mjs cjs ts tsx json json5 jsonc
  html htm css scss sass less svelte vue astro
  py rb php pl lua r jl sh bash zsh fish ps1 bat
  c h cpp hpp cc cxx m mm swift java kt kts scala go rs zig dart
  sql graphql gql proto
  yml yaml toml ini cfg conf env properties plist xml
  csv tsv
  Dockerfile dockerfile makefile mk cmake gradle
  gitignore gitattributes editorconfig eslintrc prettierrc npmrc nvmrc
  diff patch lock sum mod
  vim el lisp clj cljs ex exs erl hs ml fs fsx nim v
)

for u in "${UTIS[@]}"; do duti -s "$APP" "$u" all 2>/dev/null; done
for e in "${EXTS[@]}"; do duti -s "$APP" ".$e" all 2>/dev/null; done

echo "Handlers mis à jour vers $APP"
echo "Vérif :"
for e in txt md js sh json yaml; do printf '  .%-5s -> %s\n' "$e" "$(duti -x "$e" 2>/dev/null | sed -n 1p)"; done
