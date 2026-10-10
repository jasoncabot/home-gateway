#!/bin/sh
# Keeps a Cloudflare A record pointed at this network's public IPv4 address.
set -eu

: "${CF_API_TOKEN:?CF_API_TOKEN is required}"
: "${CF_ZONE_ID:?CF_ZONE_ID is required}"
: "${CF_RECORD_NAME:?CF_RECORD_NAME is required}"
INTERVAL="${INTERVAL:-3600}"
TTL="${TTL:-60}"
LAST_IP=""
API="https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records"

cf() { curl -fsS -H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json" "$@"; }

public_ip() {
  for url in https://api.ipify.org https://ipv4.icanhazip.com https://checkip.amazonaws.com; do
    ip=$(curl -4 -fsS --max-time 10 "$url" 2>/dev/null | tr -d '[:space:]') || continue
    case "$ip" in *[!0-9.]*|"") continue ;; esac
    echo "$ip"; return 0
  done
  return 1
}

sync() {
  ip=$(public_ip) || { echo "$(date -u +%FT%TZ) could not determine public IP"; return 1; }
  # Same IP as the last successful sync: nothing to do, don't touch the Cloudflare API.
  [ "$ip" = "$LAST_IP" ] && return 0
  rec=$(cf "${API}?type=A&name=${CF_RECORD_NAME}") || { echo "$(date -u +%FT%TZ) Cloudflare lookup failed"; return 1; }
  id=$(echo "$rec" | jq -r '.result[0].id // empty')
  cur=$(echo "$rec" | jq -r '.result[0].content // empty')
  body=$(jq -nc --arg n "$CF_RECORD_NAME" --arg ip "$ip" --argjson ttl "$TTL" \
    '{type:"A",name:$n,content:$ip,ttl:$ttl,proxied:false}')
  if [ -z "$id" ]; then
    cf -X POST -d "$body" "$API" >/dev/null || return 1
    echo "$(date -u +%FT%TZ) created ${CF_RECORD_NAME} -> ${ip}"
  elif [ "$cur" != "$ip" ]; then
    cf -X PUT -d "$body" "${API}/${id}" >/dev/null || return 1
    echo "$(date -u +%FT%TZ) updated ${CF_RECORD_NAME}: ${cur} -> ${ip}"
  else
    echo "$(date -u +%FT%TZ) record already correct (${ip})"
  fi
  LAST_IP="$ip"
}

while true; do
  sync || true
  sleep "$INTERVAL"
done
