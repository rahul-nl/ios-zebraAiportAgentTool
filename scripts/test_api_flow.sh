#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_PATH="$ROOT_DIR/Config/runtime-config.json"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "Missing config file: $CONFIG_PATH"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required"
  exit 1
fi

# Optional env override:
# TEST_PNR=ABC123 ./scripts/test_api_flow.sh
# Optional direct token mode (skip auth call):
# POSTMAN_BEARER_TOKEN="<token>" TEST_PNR=ABC123 ./scripts/test_api_flow.sh

EVAL_VARS="$($(command -v python3) - <<'PY'
import json
import shlex
import urllib.parse
from pathlib import Path

cfg = json.loads(Path('Config/runtime-config.json').read_text())
auth_headers = cfg.get('authHeaders', {})
zpl_headers = cfg.get('zplHeaders', {})
auth_body = cfg.get('authBodyTemplate', {})

pairs = {
  'AUTH_BASE': cfg.get('authBaseUrl', ''),
  'AUTH_PATH': cfg.get('authTokenPath', ''),
  'AUTH_METHOD': cfg.get('authMethod', 'POST'),
  'AUTH_CT': auth_headers.get('Content-Type', 'application/json'),
  'ZPL_BASE': cfg.get('zplBaseUrl', ''),
  'ZPL_PATH': cfg.get('zplPath', ''),
  'ZPL_METHOD': cfg.get('zplMethod', 'POST'),
  'ZPL_CT': zpl_headers.get('Content-Type', 'application/json'),
  'ZPL_REQUIRES_BEARER_AUTH': str(cfg.get('zplRequiresBearerAuth', True)).lower(),
  'TIMEOUT': str(cfg.get('requestTimeoutSeconds', 20)),
  'AUTH_FORM': urllib.parse.urlencode(auth_body),
  'AUTH_JSON': json.dumps(auth_body),
}

for key, value in pairs.items():
  print(f"{key}={shlex.quote(str(value))}")
PY
)"

eval "$EVAL_VARS"

AUTH_URL="$AUTH_BASE$AUTH_PATH"
ZPL_URL="$ZPL_BASE$ZPL_PATH"
TEST_PNR="${TEST_PNR:-ABC123}"
auth_token="${POSTMAN_BEARER_TOKEN:-}"
requires_bearer_auth="${ZPL_REQUIRES_BEARER_AUTH:-true}"

if [[ "$requires_bearer_auth" != "true" ]]; then
  echo "[1/2] Auth request"
  echo "Skipped (zplRequiresBearerAuth=false)"
elif [[ -n "$auth_token" ]]; then
  echo "[1/2] Auth request"
  echo "Skipped (using POSTMAN_BEARER_TOKEN from environment)"
else
  echo "[1/2] Auth request"
  echo "URL: $AUTH_URL"

  if [[ "${AUTH_CT:l}" == *"application/x-www-form-urlencoded"* ]]; then
    AUTH_RESP=$(curl -sS -m "$TIMEOUT" -X "$AUTH_METHOD" "$AUTH_URL" -H "Content-Type: $AUTH_CT" --data "$AUTH_FORM" -w "\nHTTP_STATUS:%{http_code}")
  else
    AUTH_RESP=$(curl -sS -m "$TIMEOUT" -X "$AUTH_METHOD" "$AUTH_URL" -H "Content-Type: $AUTH_CT" --data "$AUTH_JSON" -w "\nHTTP_STATUS:%{http_code}")
  fi

  AUTH_STATUS=$(printf "%s" "$AUTH_RESP" | sed -n 's/^HTTP_STATUS://p')
  AUTH_BODY=$(printf "%s" "$AUTH_RESP" | sed '/^HTTP_STATUS:/d')

  echo "Auth status: $AUTH_STATUS"

  if [[ "$AUTH_STATUS" -ge 200 && "$AUTH_STATUS" -lt 300 ]]; then
    auth_token=$(printf "%s" "$AUTH_BODY" | python3 -c 'import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get("access_token", ""))
except Exception:
    print("")
')
    if [[ -z "$auth_token" ]]; then
      echo "Auth response did not contain access_token"
      echo "Auth body (first 500 chars):"
      printf "%s\n" "$AUTH_BODY" | cut -c1-500
      exit 2
    fi
    echo "Auth token: received"
  else
    echo "Auth failed"
    echo "Auth body (first 500 chars):"
    printf "%s\n" "$AUTH_BODY" | cut -c1-500
    exit 2
  fi
fi

if [[ -n "$auth_token" ]]; then
  # Print key claims so OAuth policy mismatches can be diagnosed quickly.
  python3 - <<'PY' "$auth_token"
import base64
import json
import sys

tok = sys.argv[1]
parts = tok.split('.')
if len(parts) != 3:
    print('Token claims: <unavailable>')
    raise SystemExit(0)

payload = parts[1] + '=' * (-len(parts[1]) % 4)
claims = json.loads(base64.urlsafe_b64decode(payload.encode()).decode())

print('Token claims summary:')
for key in ['aud', 'iss', 'appid', 'azp', 'tid']:
    if key in claims:
        print(f"  {key}: {claims[key]}")

roles = claims.get('roles')
scp = claims.get('scp')
print(f"  roles: {roles if roles else '<missing>'}")
print(f"  scp: {scp if scp else '<missing>'}")
PY
fi

ZPL_PAYLOAD="$($(command -v python3) - <<PY
import json
import os
print(json.dumps({"pnr": os.environ.get("TEST_PNR", "ABC123")}, separators=(",", ":")))
PY
)"

echo "[2/2] ZPL request"
echo "URL: $ZPL_URL"
echo "Payload (raw JSON): $ZPL_PAYLOAD"

zpl_cmd=(curl -sS -m "$TIMEOUT" -X "$ZPL_METHOD" "$ZPL_URL" -H "Content-Type: $ZPL_CT" --data-binary "$ZPL_PAYLOAD" -w "\nHTTP_STATUS:%{http_code}")
if [[ -n "$auth_token" ]]; then
  zpl_cmd+=( -H "Authorization: Bearer $auth_token" )
fi
ZPL_RESP=$("${zpl_cmd[@]}")
ZPL_STATUS=$(printf "%s" "$ZPL_RESP" | sed -n 's/^HTTP_STATUS://p')
ZPL_BODY=$(printf "%s" "$ZPL_RESP" | sed '/^HTTP_STATUS:/d')

echo "ZPL status: $ZPL_STATUS"
if [[ "$ZPL_STATUS" -ge 200 && "$ZPL_STATUS" -lt 300 ]]; then
  echo "ZPL call succeeded"
  echo "ZPL body (first 800 chars):"
  printf "%s\n" "$ZPL_BODY" | cut -c1-800
  exit 0
fi

echo "ZPL call failed"
echo "ZPL body (first 800 chars):"
printf "%s\n" "$ZPL_BODY" | cut -c1-800

if printf "%s" "$ZPL_BODY" | grep -q "MisMatchingOAuthClaims"; then
  echo ""
  echo "Diagnostic: OAuth claims mismatch detected."
  echo "Checklist to fix:"
  echo "  1) In Power Automate trigger auth policy, allow this app registration (client app id)."
  echo "  2) Ensure tenant/issuer matches token issuer and tid."
  echo "  3) Grant admin consent for required application permissions so token includes roles/scp if policy requires them."
  echo "  4) Keep scope as https://service.flow.microsoft.com/.default for client credentials."
fi

exit 3
