#!/bin/sh
# Modifie le code compilé de Documenso. Chaque motif doit être trouvé exactement :
# un écart à une montée de version arrête le build au lieu de perdre le correctif.
#  - cookie `lang` : 6 mois au lieu de 2 ans (politique cookies 08, rétention 11 § 2.7) ;
#  - IP du signataire : CF-Connecting-IP d'abord. Le premier élément de X-Forwarded-For
#    vient du client et se falsifie ; or l'IP figure dans la preuve de signature.
set -eu

BUILD="${DOCUMENSO_BUILD_DIR:-/app/apps/remix/build/server}"
BUNDLE="$(ls "$BUILD"/assets/server-build-*.js)"
HONO="$BUILD/hono/packages/lib/universal/get-ip-address.js"

fail() { echo "patch documenso : $1" >&2; exit 1; }

[ "$(printf '%s\n' "$BUNDLE" | wc -l)" -eq 1 ] || fail "plusieurs server-build"
[ -f "$HONO" ] || fail "get-ip-address.js introuvable"

[ "$(grep -c 'maxAge: 60 \* 60 \* 24 \* 365 \* 2,' "$BUNDLE")" -eq 1 ] || fail "durée du cookie lang introuvable"
grep -q '^const langCookie = createCookie("lang", {$' "$BUNDLE" || fail "cookie lang introuvable"
sed -i '/^const langCookie = createCookie("lang", {$/,/^});$/s/maxAge: 60 \* 60 \* 24 \* 365 \* 2,/maxAge: 60 * 60 * 24 * 182,/' "$BUNDLE"
[ "$(grep -c 'maxAge: 60 \* 60 \* 24 \* 182,' "$BUNDLE")" -eq 1 ] || fail "durée du cookie lang non modifiée"

CF='  const cf = req.headers.get("cf-connecting-ip");\n  if (cf) return cf;'
[ "$(grep -c '^const getIpAddress = (req) => {$' "$BUNDLE")" -eq 1 ] || fail "getIpAddress introuvable (bundle)"
[ "$(grep -c '^const getIpAddress = req => {$' "$HONO")" -eq 1 ] || fail "getIpAddress introuvable (hono)"
sed -i "/^const getIpAddress = (req) => {\$/a\\$CF" "$BUNDLE"
sed -i "/^const getIpAddress = req => {\$/a\\$CF" "$HONO"
[ "$(grep -c 'cf-connecting-ip");$' "$HONO")" -ge 1 ] || fail "IP non modifiée (hono)"
