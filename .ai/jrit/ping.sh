#!/usr/bin/env bash
# Ping a Telegram bot for a card or a run end. Run as a cezar check node:
#   bash .ai/jrit/ping.sh card <node id>   the node whose output holds the card text
#   bash .ai/jrit/ping.sh end <end node id> [<node id>]   a named node's output is appended to the message
# Reads ${JRIT_PING_CONF:-$HOME/.config/jrit/ping.conf} (TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID);
# unconfigured is a no-op. Always exits 0 so a failed ping never fails the graph.
set -uo pipefail

kind=${1:-} node=${2:-} extra=${3:-}
case "$kind" in card|end) ;; *) echo "ping: usage: ping.sh card <node id> | ping.sh end <end node id> [<node id>]"; exit 0 ;; esac
[ -n "$node" ] || { echo "ping: usage: ping.sh card <node id> | ping.sh end <end node id> [<node id>]"; exit 0; }

conf=${JRIT_PING_CONF:-$HOME/.config/jrit/ping.conf}
TELEGRAM_BOT_TOKEN='' TELEGRAM_CHAT_ID=''
# shellcheck disable=SC1090
[ -f "$conf" ] && . "$conf"
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo "ping: unconfigured ($conf)"; exit 0
fi

for v in CEZ_API_URL CEZ_PROJECT_ID CEZ_RUN_ID; do
  [ -n "${!v:-}" ] || { echo "ping: $v is not set; not sent"; exit 0; }
done

api="$CEZ_API_URL/api/v1/p/$CEZ_PROJECT_ID/runs/$CEZ_RUN_ID"
case "$api" in
  file://*) rec="$(cat "${api#file://}" 2>/dev/null)" ;;
  *) rec="$(curl -sf --max-time 10 "$api" 2>/dev/null)" ;;
esac
[ -n "$rec" ] || { echo "ping: cannot read run $CEZ_RUN_ID from $api; not sent"; exit 0; }

wf="$(printf '%s' "$rec" | jq -r '.workflow // "unknown"' 2>/dev/null)"
head8="$(printf '%s' "$CEZ_RUN_ID" | cut -c1-8)"
if [ "$kind" = card ]; then
  out="$(printf '%s' "$rec" | jq -r --arg n "$node" '.graphState.outputs[$n].output // ""' 2>/dev/null)"
  last="$(printf '%s\n' "$out" | awk 'NF{l=$0} END{print l}')"
  first="$(printf '%s\n' "$out" | awk 'NF{print; exit}')"
  q="$(printf '%s' "$last" | jq -r '.questions[0].question // empty' 2>/dev/null)"
  [ -n "$q" ] || q=$first
  text="$CEZ_PROJECT_ID/$head8 $wf card at $node: $q
answer: curl -s -X POST $CEZ_API_URL/api/v1/p/$CEZ_PROJECT_ID/runs/$CEZ_RUN_ID/messages -H 'content-type: application/json' -d '{\"text\":\"<your answer>\",\"images\":[]}'"
  tag=card
else
  st="$(printf '%s' "$rec" | jq -r --arg n "$node" '[.workflowDef.graph.nodes[]? | select(.id == $n) | .status][0] // "unknown"' 2>/dev/null)"
  err="$(printf '%s' "$rec" | jq -r '.error // "ok"' 2>/dev/null)"
  text="$CEZ_PROJECT_ID/$head8 $wf ended $node (${st:-unknown}): ${err:-ok}"
  tag="end $node"
  if [ -n "$extra" ]; then
    more="$(printf '%s' "$rec" | jq -r --arg n "$extra" '.graphState.outputs[$n].output // ""' 2>/dev/null | sed -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}')"
    [ -z "$more" ] || text="$text
$more"
  fi
fi

code="$(curl -s --max-time 10 -o /dev/null -w '%{http_code}' \
  -d "chat_id=$TELEGRAM_CHAT_ID" --data-urlencode "text=$text" \
  "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" 2>/dev/null)" || code=000
[ -n "$code" ] || code=000

log="${XDG_STATE_HOME:-$HOME/.local/state}/jrit/pings.log"
mkdir -p "$(dirname "$log")" 2>/dev/null
printf '%s %s %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$CEZ_RUN_ID" "$tag" "$code" >> "$log" 2>/dev/null
case "$code" in 2??) ;; *) echo "ping: send failed ($code); not sent" ;; esac
printf '%s\n' "$text"
exit 0
