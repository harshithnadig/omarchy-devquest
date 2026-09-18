#!/usr/bin/env bash
set -euo pipefail

# DevQuest Engine: Local RPG State and Activity Tracker for Developers
STATE_FILE="$HOME/.local/state/omarchy/devquest.json"
mkdir -p "$(dirname "$STATE_FILE")"
SPRINT_DURATION_SECONDS=1500

get_title() {
  local lvl=$1
  if (( lvl < 3 )); then echo "Novice Coder"
  elif (( lvl < 6 )); then echo "Script Sorcerer"
  elif (( lvl < 10 )); then echo "Code Mage"
  elif (( lvl < 15 )); then echo "Bug Slayer"
  elif (( lvl < 20 )); then echo "Rust Alchemist"
  elif (( lvl < 30 )); then echo "Kernel Archmage"
  else echo "Grand Cyber-Deity"
  fi
}

get_avatar() {
  local lvl=$1
  if (( lvl < 3 )); then echo "🌱"
  elif (( lvl < 6 )); then echo "🧙‍♂️"
  elif (( lvl < 10 )); then echo "⚔️"
  elif (( lvl < 15 )); then echo "🛡️"
  elif (( lvl < 20 )); then echo "🔮"
  elif (( lvl < 30 )); then echo "🐉"
  else echo "👑"
  fi
}

init_state() {
  local today=$(date +%Y-%m-%d)
  cat <<JSON > "$STATE_FILE"
{
  "schema_version": 2,
  "level": 1,
  "current_xp": 0,
  "max_xp": 100,
  "streak": 1,
  "last_active_date": "$today",
  "mana": 100,
  "total_commits": 0,
  "today_commits": 0,
  "quests_completed": 0,
  "quests": [
    {
      "id": "commit_quest",
      "title": "Daily Forge",
      "desc": "Make 3 commits today",
      "progress": 0,
      "goal": 3,
      "xp": 100,
      "claimed": false
    },
    {
      "id": "sprint_quest",
      "title": "Deep Work Sprint",
      "desc": "Complete a 25m focus sprint",
      "progress": 0,
      "goal": 1,
      "xp": 75,
      "claimed": false
    },
    {
      "id": "pr_quest",
      "title": "Open Source Hero",
      "desc": "Submit or review a PR",
      "progress": 0,
      "goal": 1,
      "xp": 200,
      "claimed": false
    }
  ],
  "sprint_started_at": null,
  "sprint_duration_seconds": 1500
}
JSON
}

[[ -f "$STATE_FILE" ]] || init_state

migrate_state() {
  local schema_version
  schema_version=$(jq -r '.schema_version // 1' "$STATE_FILE" 2>/dev/null || echo 1)
  [[ "$schema_version" =~ ^[0-9]+$ ]] || schema_version=1
  if (( schema_version < 2 )); then
    local tmp
    tmp=$(mktemp "${STATE_FILE}.tmp.XXXXXX")
    jq '
      .schema_version = 2 |
      .sprint_started_at = null |
      .sprint_duration_seconds = 1500 |
      (.quests[]? | select(.id == "pr_quest") | .progress) = 0 |
      (.quests[]? | select(.id == "pr_quest") | .claimed) = false
    ' "$STATE_FILE" >"$tmp" && mv -f -- "$tmp" "$STATE_FILE"
  fi
}

migrate_state

count_commits_today() {
  local total=0
  local git_dir repo repo_author count
  while IFS= read -r git_dir; do
    repo=${git_dir%/.git}
    repo_author=$(git -C "$repo" config user.name 2>/dev/null || true)
    [[ -n "$repo_author" ]] || repo_author=$(git config --global user.name 2>/dev/null || true)
    [[ -n "$repo_author" ]] || continue
    count=$(git -C "$repo" log --since="midnight" --author="$repo_author" --format='%H' 2>/dev/null | wc -l)
    total=$((total + count))
  done < <(find "$HOME/Work" -maxdepth 3 -type d -name .git -print 2>/dev/null)
  echo "$total"
}

refresh_commit_progress() {
  local commits_today tmp
  commits_today=$(count_commits_today)
  [[ "$commits_today" =~ ^[0-9]+$ ]] || commits_today=0
  tmp=$(mktemp "${STATE_FILE}.tmp.XXXXXX")
  jq \
    --argjson commits "$commits_today" \
    '.today_commits = $commits | .quests[0].progress = $commits' \
    "$STATE_FILE" >"$tmp" && mv -f -- "$tmp" "$STATE_FILE"
}

complete_sprint_if_ready() {
  local started now elapsed tmp
  started=$(jq -r '.sprint_started_at // empty' "$STATE_FILE")
  [[ "$started" =~ ^[0-9]+$ ]] || return 0
  now=$(date +%s)
  elapsed=$((now - started))
  if (( elapsed >= SPRINT_DURATION_SECONDS )); then
    tmp=$(mktemp "${STATE_FILE}.tmp.XXXXXX")
    jq \
      '.sprint_started_at = null | .quests[1].progress = 1' \
      "$STATE_FILE" >"$tmp" && mv -f -- "$tmp" "$STATE_FILE"
    "$0" add-xp 35 "Focus Sprint completed" >/dev/null
  fi
}

sync_today() {
  local today=$(date +%Y-%m-%d)
  local last_date=$(jq -r '.last_active_date // ""' "$STATE_FILE")
  
  if [[ "$last_date" != "$today" ]]; then
    # New day: check streak and reset daily quests
    local streak=$(jq -r '.streak // 1' "$STATE_FILE")
    local yesterday=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d 2>/dev/null)
    
    if [[ "$last_date" == "$yesterday" ]]; then
      streak=$((streak + 1))
    elif [[ -n "$last_date" ]]; then
      streak=1
    fi
    
    # Count commits today across active user workspaces.
    local commits_today
    commits_today=$(count_commits_today)
    [[ "$commits_today" =~ ^[0-9]+$ ]] || commits_today=0
    
    local tmp=$(mktemp)
    jq \
      --arg today "$today" \
      --argjson streak "$streak" \
      --argjson commits "$commits_today" \
      '
        .last_active_date = $today |
        .streak = $streak |
        .today_commits = $commits |
        .mana = 100 |
        .quests[0].progress = $commits |
        .quests[0].claimed = false |
        .quests[1].progress = 0 |
        .quests[1].claimed = false |
        .quests[2].progress = 0 |
        .quests[2].claimed = false |
        .sprint_started_at = null
      ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  fi
}

sync_today

cmd="${1:-get}"

case "$cmd" in
  get)
    refresh_commit_progress
    complete_sprint_if_ready
    lvl=$(jq -r '.level' "$STATE_FILE")
    title=$(get_title "$lvl")
    avatar=$(get_avatar "$lvl")
    sprint_started_at=$(jq -r '.sprint_started_at // empty' "$STATE_FILE")
    sprint_remaining=0
    sprint_active=false
    if [[ "$sprint_started_at" =~ ^[0-9]+$ ]]; then
      sprint_elapsed=$(( $(date +%s) - sprint_started_at ))
      if (( sprint_elapsed < SPRINT_DURATION_SECONDS )); then
        sprint_active=true
        sprint_remaining=$((SPRINT_DURATION_SECONDS - sprint_elapsed))
      fi
    fi
    
    jq \
      --arg title "$title" \
      --arg avatar "$avatar" \
      --argjson sprint_active "$sprint_active" \
      --argjson sprint_remaining "$sprint_remaining" \
      '. + { title: $title, avatar: $avatar, sprint_active: $sprint_active, sprint_remaining_seconds: $sprint_remaining }' "$STATE_FILE"
    ;;
    
  add-xp)
    amount=${2:-25}
    reason=${3:-"Coding activity"}

    if ! [[ "$amount" =~ ^[0-9]+$ ]] || (( amount > 10000 )); then
      echo "XP amount must be a non-negative integer no greater than 10000." >&2
      exit 1
    fi
    reason=${reason:0:160}
    
    current_xp=$(jq -r '.current_xp' "$STATE_FILE")
    max_xp=$(jq -r '.max_xp' "$STATE_FILE")
    lvl=$(jq -r '.level' "$STATE_FILE")
    
    new_xp=$((current_xp + amount))
    leveled_up=false
    
    while (( new_xp >= max_xp )); do
      new_xp=$((new_xp - max_xp))
      lvl=$((lvl + 1))
      max_xp=$((max_xp + (lvl * 50)))
      leveled_up=true
    done
    
    tmp=$(mktemp)
    jq \
      --argjson lvl "$lvl" \
      --argjson cxp "$new_xp" \
      --argjson mxp "$max_xp" \
      '
        .level = $lvl |
        .current_xp = $cxp |
        .max_xp = $mxp
      ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
      
    if [[ "$leveled_up" == "true" ]]; then
      title=$(get_title "$lvl")
      omarchy-notification-send -g 🎮 "LEVEL UP! Lv. $lvl $title" "You earned $amount XP for $reason!" >/dev/null 2>&1 || true
    fi
    echo "XP added: +$amount (Level $lvl: $new_xp / $max_xp XP)"
    ;;
    
  claim-quest)
    quest_id="${2:-}"
    [[ -n "$quest_id" ]] || exit 1
    
    reward=$(jq -r --arg id "$quest_id" '.quests[] | select(.id == $id and .claimed == false and .progress >= .goal) | .xp' "$STATE_FILE")
    
    if [[ -n "$reward" && "$reward" != "null" ]]; then
      tmp=$(mktemp)
      jq --arg id "$quest_id" '
        .quests = (.quests | map(if .id == $id then .claimed = true else . end)) |
        .quests_completed = (.quests_completed + 1)
      ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
      
      "$0" add-xp "$reward" "Completed Quest ($quest_id)"
    fi
    ;;
    
  sprint)
    complete_sprint_if_ready
    started=$(jq -r '.sprint_started_at // empty' "$STATE_FILE")
    if [[ "$started" =~ ^[0-9]+$ ]]; then
      elapsed=$(( $(date +%s) - started ))
      if (( elapsed < SPRINT_DURATION_SECONDS )); then
        remaining=$((SPRINT_DURATION_SECONDS - elapsed))
        echo "Focus sprint in progress: $(( (remaining + 59) / 60 )) minutes remaining."
      else
        echo "Focus sprint complete: +35 XP awarded."
      fi
    else
      tmp=$(mktemp "${STATE_FILE}.tmp.XXXXXX")
      jq \
        --argjson started "$(date +%s)" \
        '.sprint_started_at = $started | .quests[1].progress = 0 | .mana = (if .mana >= 20 then .mana - 20 else 0 end)' \
        "$STATE_FILE" >"$tmp" && mv -f -- "$tmp" "$STATE_FILE"
      echo "Focus sprint started. Return after 25 minutes to claim +35 XP."
    fi
    ;;
esac
