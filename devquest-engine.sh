#!/bin/bash

# DevQuest Engine: Local RPG State and Activity Tracker for Developers
STATE_FILE="$HOME/.local/state/omarchy/devquest.json"
mkdir -p "$(dirname "$STATE_FILE")"

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
      "progress": 1,
      "goal": 1,
      "xp": 200,
      "claimed": false
    }
  ]
}
JSON
}

[[ -f "$STATE_FILE" ]] || init_state

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
    
    # Count commits today across active user workspaces
    local commits_today=0
    if [[ -d "$HOME/Work" ]]; then
      commits_today=$(find "$HOME/Work" -maxdepth 2 -name ".git" -execdir git log --since="midnight" --author="$(git config user.name 2>/dev/null || echo '')" --oneline 2>/dev/null \; | wc -l)
    fi
    
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
        .quests[1].claimed = false
      ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  fi
}

sync_today

cmd="${1:-get}"

case "$cmd" in
  get)
    lvl=$(jq -r '.level' "$STATE_FILE")
    title=$(get_title "$lvl")
    avatar=$(get_avatar "$lvl")
    
    jq \
      --arg title "$title" \
      --arg avatar "$avatar" \
      '. + { title: $title, avatar: $avatar }' "$STATE_FILE"
    ;;
    
  add-xp)
    amount=${2:-25}
    reason=${3:-"Coding activity"}
    
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
    tmp=$(mktemp)
    jq '
      .quests[1].progress = 1 |
      .mana = (if .mana >= 20 then .mana - 20 else 0 end)
    ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    
    "$0" add-xp 35 "Focus Sprint completed"
    ;;
esac
