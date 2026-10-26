#!/bin/sh
# usage: publish.sh <payload.json> [yaml|publish|get <id>]
#   yaml    (default) dry run: POST /publish, returns the cichéto YAML, publishes nothing
#   publish POST /publications: writes the cichéto to the house bàcaro, app goes live
#   get     GET /publications/<id>: the currently published cichéto (for updates)
D=$(dirname "$0"); BASE=https://spritzdepot.desktoponfire.com
TOKEN=$(tr -d ' \n' < "$D/token")
EXP=$(printf '%s' "$TOKEN" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | grep -oE '"exp":[0-9]+' | cut -d: -f2)
if [ -n "$EXP" ] && [ "$EXP" -le "$(date +%s)" ]; then
  echo "Token expired $(date -d @$EXP). Log in at $BASE, run localStorage.spritz_token in the console, and save it to $D/token" >&2; exit 2
fi
case "${2:-yaml}" in
  get)     curl -sS -w '\nHTTP %{http_code}\n' -H "Authorization: Bearer $TOKEN" "$BASE/publications/$3" ;;
  publish) EP=/publications ;;
  *)       EP=/publish ;;
esac
[ -n "$EP" ] && curl -sS --max-time 600 -w '\nHTTP %{http_code}\n' -X POST "$BASE$EP" \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" --data @"$1"
