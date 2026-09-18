#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_HOME=$(mktemp -d)
trap 'rm -rf "$TEST_HOME"' EXIT

run_engine() {
  HOME="$TEST_HOME" bash "$ROOT_DIR/devquest-engine.sh" "$@"
}

initial=$(run_engine get)
jq -e '.schema_version == 2 and .quests[2].progress == 0 and .sprint_active == false' >/dev/null <<<"$initial"

started=$(run_engine sprint)
grep -F "Focus sprint started" <<<"$started" >/dev/null
in_progress=$(run_engine sprint)
grep -F "in progress" <<<"$in_progress" >/dev/null

state_file="$TEST_HOME/.local/state/omarchy/devquest.json"
tmp_state=$(mktemp)
jq '.sprint_started_at = ((now | floor) - 1500)' "$state_file" >"$tmp_state"
mv -f -- "$tmp_state" "$state_file"

completed=$(run_engine get)
jq -e '.sprint_active == false and .sprint_remaining_seconds == 0 and .quests[1].progress == 1 and .current_xp == 35' >/dev/null <<<"$completed"

if run_engine add-xp -1 >/dev/null 2>&1; then
  echo "negative XP was accepted" >&2
  exit 1
fi

echo "DevQuest timer and migration smoke test passed"
