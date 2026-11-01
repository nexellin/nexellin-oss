#!/bin/sh
# Modifie le code compilé de Documenso. Chaque motif doit être trouvé exactement :
# un écart à une montée de version arrête le build au lieu de perdre le correctif.
#  - cookie `lang` : 6 mois au lieu de 2 ans (politique cookies 08, rétention 11 § 2.7) ;
#  - IP du signataire : CF-Connecting-IP d'abord. Le premier élément de X-Forwarded-For
#    vient du client et se falsifie ; or l'IP figure dans la preuve de signature ;
#  - marque Documenso : ni QR code, ni logo, ni « Propulsé par » sur le certificat, le journal
#    d'audit et l'écran de signature, quel que soit le plan de l'organisation.
set -eu

BUILD="${DOCUMENSO_BUILD_DIR:-/app/apps/remix/build/server}"
BUNDLE="$(ls "$BUILD"/assets/server-build-*.js)"
HONO="$BUILD/hono/packages/lib/universal/get-ip-address.js"

PDF="$BUILD/hono/packages/lib/server-only/pdf"

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

# force_marque <fichier> <nombre de sites attendu>
force_marque() {
  [ "$(grep -c 'organisationClaim\.flags\.hidePoweredBy' "$1")" -eq "$2" ] || fail "sites de hidePoweredBy changés : $1"
  sed -i 's/organisationClaim\.flags\.hidePoweredBy/true/g' "$1"
  if grep -q 'flags\.hidePoweredBy' "$1"; then fail "hidePoweredBy non forcé : $1"; fi
}
# Écrans : chargeurs des routes d'embed et d'impression. PDF : scellement (2) et téléchargement (2).
force_marque "$BUNDLE" 7
force_marque "$(ls "$BUILD"/assets/seal-document.handler-*.js)" 2
force_marque "$PDF/generate-certificate-pdf.js" 1
force_marque "$PDF/generate-audit-log-pdf.js" 1

# Toute autre occurrence du drapeau arrête le build, formes `?.` et fichiers inconnus compris.
# Laissées en place : pied de page des e-mails et branding du destinataire.
ATTENDU='2 assets/get-email-context.js
1 assets/server-build.js
2 hono/packages/lib/server-only/email/get-email-context.js'
RESTES="$(cd "$BUILD" && find . -type f -name '*.js' -exec grep -HEo 'flags\??\.hidePoweredBy' {} + \
  | sed -E 's#^\./##; s#^(assets/(server-build|get-email-context))-[^/:]*\.js:#\1.js:#; s/:.*$//' | LC_ALL=C sort | uniq -c | awk '{print $1, $2}')"
[ "$RESTES" = "$ATTENDU" ] || fail "occurrences de hidePoweredBy non traitées :
$RESTES"
