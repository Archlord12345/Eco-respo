#!/usr/bin/env bash
# Client HTTP pour le BaaS Appwrite (clé serveur uniquement, jamais dans Flutter).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${APPWRITE_ENV_FILE:-$ROOT/.env}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

ENDPOINT="${APPWRITE_ENDPOINT:-https://appwrite.kernelforge.codes/v1}"
ENDPOINT="${ENDPOINT%/}"
PROJECT="${APPWRITE_PROJECT_ID:-6aad2f1a000a6a6de281}"
DB="${APPWRITE_DATABASE_ID:-eco_responsable_db}"
API_KEY="${APPWRITE_API_KEY:-}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <commande> [args]

Charge \$ROOT/.env (APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID, APPWRITE_API_KEY).

Commandes:
  ping                         GET /health
  version                      GET /health/version
  users                        GET /users
  databases                    GET /databases
  collections                  GET /databases/\$DB/collections
  collection <id>              GET une collection
  documents <collection>       GET documents d'une collection
  buckets                      GET /storage/buckets
  functions                    GET /functions
  teams                        GET /teams
  get <path>                   GET arbitraire (ex. /users)
  post <path> [json]           POST JSON
  put <path> [json]            PUT JSON
  patch <path> [json]          PATCH JSON
  delete <path>                DELETE

Exemples:
  tool/appwrite.sh ping
  tool/appwrite.sh collections
  tool/appwrite.sh documents waste_reports
  tool/appwrite.sh get /users
EOF
}

need_key() {
  if [[ -z "$API_KEY" ]]; then
    echo "APPWRITE_API_KEY manquante. Définis-la dans $ENV_FILE" >&2
    exit 1
  fi
}

pretty() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; d=sys.stdin.read();
try:
  print(json.dumps(json.loads(d), indent=2, ensure_ascii=False))
except Exception:
  sys.stdout.write(d if d.endswith("\n") else d+"\n")'
  else
    cat
  fi
}

aw() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  local url="$ENDPOINT$path"
  local tmp
  tmp="$(mktemp)"
  local args=(
    -sS
    -X "$method"
    -H "Content-Type: application/json"
    -H "X-Appwrite-Project: $PROJECT"
    -H "X-Appwrite-Key: $API_KEY"
    -w "%{http_code}"
    -o "$tmp"
  )
  if [[ -n "$body" ]]; then
    args+=(-d "$body")
  fi
  local code
  code="$(curl "${args[@]}" "$url")"
  local payload
  payload="$(cat "$tmp")"
  rm -f "$tmp"
  echo "# $method $path -> HTTP $code" >&2
  if [[ -n "$payload" ]]; then
    printf '%s' "$payload" | pretty
    echo
  fi
  if [[ "$code" -ge 400 ]]; then
    exit 1
  fi
}

cmd="${1:-}"
shift || true

case "$cmd" in
  ""|-h|--help|help)
    usage
    ;;
  ping)
    need_key
    aw GET /health
    ;;
  version)
    need_key
    aw GET /health/version
    ;;
  users)
    need_key
    aw GET /users
    ;;
  databases)
    need_key
    aw GET /databases
    ;;
  collections)
    need_key
    aw GET "/databases/$DB/collections"
    ;;
  collection)
    need_key
    [[ -n "${1:-}" ]] || { echo "collection <id> requis" >&2; exit 1; }
    aw GET "/databases/$DB/collections/$1"
    ;;
  documents)
    need_key
    [[ -n "${1:-}" ]] || { echo "documents <collection> requis" >&2; exit 1; }
    aw GET "/databases/$DB/collections/$1/documents"
    ;;
  buckets)
    need_key
    aw GET /storage/buckets
    ;;
  functions)
    need_key
    aw GET /functions
    ;;
  teams)
    need_key
    aw GET /teams
    ;;
  get|GET)
    need_key
    [[ -n "${1:-}" ]] || { echo "get <path> requis" >&2; exit 1; }
    path="$1"
    [[ "$path" == /* ]] || path="/$path"
    aw GET "$path"
    ;;
  post|POST)
    need_key
    [[ -n "${1:-}" ]] || { echo "post <path> [json] requis" >&2; exit 1; }
    path="$1"
    [[ "$path" == /* ]] || path="/$path"
    aw POST "$path" "${2:-{}}"
    ;;
  put|PUT)
    need_key
    [[ -n "${1:-}" ]] || { echo "put <path> [json] requis" >&2; exit 1; }
    path="$1"
    [[ "$path" == /* ]] || path="/$path"
    aw PUT "$path" "${2:-{}}"
    ;;
  patch|PATCH)
    need_key
    [[ -n "${1:-}" ]] || { echo "patch <path> [json] requis" >&2; exit 1; }
    path="$1"
    [[ "$path" == /* ]] || path="/$path"
    aw PATCH "$path" "${2:-{}}"
    ;;
  delete|DELETE)
    need_key
    [[ -n "${1:-}" ]] || { echo "delete <path> requis" >&2; exit 1; }
    path="$1"
    [[ "$path" == /* ]] || path="/$path"
    aw DELETE "$path"
    ;;
  *)
    echo "Commande inconnue: $cmd" >&2
    usage >&2
    exit 1
    ;;
esac
