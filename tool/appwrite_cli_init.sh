#!/usr/bin/env bash
# Initialise / resynchronise le projet Appwrite Cloud avec la CLI officielle.
# Idempotent : relançable sans risque. Nécessite `appwrite login` au préalable.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ORG_ID="${APPWRITE_ORGANIZATION_ID:-6a8c3a75eab6eb87c22e}"
PROJECT_ID="${APPWRITE_PROJECT_ID:-eco-responsable-cm}"
PROJECT_NAME="Eco-Responsable"
REGION="${APPWRITE_REGION:-fra}"
APP_ID="com.eco.kf"
DB="eco_responsable_db"
SEED="${SEED:-1}"

command -v appwrite >/dev/null || { echo "CLI appwrite absente : npm i -g appwrite-cli" >&2; exit 1; }
appwrite whoami >/dev/null 2>&1 || { echo "Non connecté : lance 'appwrite login'" >&2; exit 1; }

log() { printf '\n== %s\n' "$*"; }

log "Projet $PROJECT_ID"
if ! appwrite organization get-project --organization-id "$ORG_ID" --project-id "$PROJECT_ID" --json >/dev/null 2>&1; then
  appwrite organization create-project --organization-id "$ORG_ID" \
    --project-id "$PROJECT_ID" --name "$PROJECT_NAME" --region "$REGION" --json
fi

if [[ ! -f appwrite.config.json ]]; then
  appwrite init project --organization-id "$ORG_ID" --project-id "$PROJECT_ID" \
    --project-name "$PROJECT_NAME" -f
fi

log "Plateformes Flutter ($APP_ID)"
existing="$(appwrite project list-platforms --json | python3 -c 'import json,sys; print(" ".join(p["$id"] for p in json.load(sys.stdin)["platforms"]))')"
has() { [[ " $existing " == *" $1 "* ]]; }
has eco-android || appwrite project create-android-platform --platform-id eco-android --name "eco-respo mobile"  --application-id "$APP_ID" --json
has eco-apple   || appwrite project create-apple-platform   --platform-id eco-apple   --name "eco-respo apple"   --bundle-identifier "$APP_ID" --json
has eco-linux   || appwrite project create-linux-platform   --platform-id eco-linux   --name "eco-respo linux"   --package-name "$APP_ID" --json
has eco-windows || appwrite project create-windows-platform --platform-id eco-windows --name "eco-respo windows" --package-identifier-name "$APP_ID" --json

log "Schéma (appwrite.config.json -> Cloud)"
python3 tool/gen_appwrite_config.py
appwrite push settings -f
appwrite push table --all -f
appwrite push bucket --all -f

if [[ "$SEED" == "1" ]]; then
  log "Données de départ"
  P=(--permissions 'read("any")' --permissions 'update("users")' --permissions 'delete("users")')
  row() { # table id json
    appwrite tablesdb get-row --database-id "$DB" --table-id "$1" --row-id "$2" --json >/dev/null 2>&1 \
      || appwrite tablesdb create-row --database-id "$DB" --table-id "$1" --row-id "$2" "${P[@]}" --data "$3" --json | grep '"\$id"'
  }
  row reward_items rw_mtn     '{"type":"mobileMoneyCredit","pointsCost":1000,"title":"Crédit Mobile MoMo","description":"À partir de 1 000 pts","imageKey":"reward_mtn","enabled":true}'
  row reward_items rw_voucher '{"type":"voucher","pointsCost":1500,"title":"Bons d'"'"'achat","description":"À partir de 1 500 pts","imageKey":"reward_voucher","enabled":true}'
  row reward_items rw_partner '{"type":"partnerPerk","pointsCost":2000,"title":"Avantages partenaires","description":"À partir de 2 000 pts","imageKey":"reward_partner","enabled":true}'
  while IFS='|' read -r id district color lat lng; do
    row zones "$id" "{\"city\":\"Yaoundé\",\"district\":\"$district\",\"assignedOperators\":[],\"collectionFrequency\":\"2x / semaine\",\"color\":\"$color\",\"centerLat\":$lat,\"centerLng\":$lng}"
  done <<'EOF'
z_centre|Centre|#7E57C2|3.866|11.516
z_nord|Nord|#5C6BC0|3.915|11.52
z_est|Est|#26A69A|3.86|11.56
z_ouest|Ouest|#66BB6A|3.86|11.47
z_sud|Sud|#42A5F5|3.80|11.52
EOF
fi

log "Terminé"
appwrite project list-platforms --json | python3 -c 'import json,sys; [print(" -", p["type"].ljust(8), p["name"]) for p in json.load(sys.stdin)["platforms"]]'
