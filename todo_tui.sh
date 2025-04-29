#!/usr/bin/env bash

# Check terminal size
if [ "$(tput lines)" -lt 30 ] || [ "$(tput cols)" -lt 125 ]; then
  echo "Please enlarge your terminal window (min 145 cols x 38 lines)."
  exit 1
fi

# Check dependencies
command -v bc >/dev/null 2>&1 || { echo "Install 'bc' first."; exit 1; }
command -v gum >/dev/null 2>&1 || { echo "Install 'gum' first: https://github.com/charmbracelet/gum"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Install 'jq' first: https://stedolan.github.io/jq/"; exit 1; }
command -v cal >/dev/null 2>&1 || { echo "Install 'cal' (bsdmainutils)"; exit 1; }

# Configuration
TODO_TUI_APP_DIR="$HOME/.todo_config"
mkdir -p "$TODO_TUI_APP_DIR"
DAY_TASK_FILE="$TODO_TUI_APP_DIR/day_tasks.json"
WEEK_TASK_FILE="$TODO_TUI_APP_DIR/week_tasks.json"
MONTH_TASK_FILE="$TODO_TUI_APP_DIR/month_tasks.json"
TOTAL_TASK_FILE="$TODO_TUI_APP_DIR/total_tasks.txt"
STARS_EARNED_FILE="$TODO_TUI_APP_DIR/stars_earned.txt"
TASK_HISTORY_FILE="$TODO_TUI_APP_DIR/task_history.txt"
STARS_FILE="$TODO_TUI_APP_DIR/stars.json"
NOTES_FILE="$TODO_TUI_APP_DIR/notes.json"
TARGET_DATE_FILE="$TODO_TUI_APP_DIR/target_dates.json"
STREAK_FILE="$TODO_TUI_APP_DIR/streak.json"
BORDER_STYLE="rounded"
COLOR_ACCENT="212"
COLOR_SECONDARY="99"
PADDING="1 2"

# Initialize files
for file in "$DAY_TASK_FILE" "$WEEK_TASK_FILE" "$MONTH_TASK_FILE"; do
  [ -f "$file" ] || echo "[]" > "$file"
done
[ -f "$TASK_HISTORY_FILE" ] || touch "$TASK_HISTORY_FILE"
[ -f "$NOTES_FILE" ] || echo "[]" > "$NOTES_FILE"
[ -f "$STARS_FILE" ] || echo '{"daily_stars": 0, "daily_reset_date": "", "weekly_stars": 0, "weekly_reset_week": "", "monthly_stars": 0, "monthly_reset_month": "", "total_stars": 0}' > "$STARS_FILE"
[ -f "$TOTAL_TASK_FILE" ] || echo "0" > "$TOTAL_TASK_FILE"
[ -f "$STARS_EARNED_FILE" ] || echo "0" > "$STARS_EARNED_FILE"
[ -f "$TARGET_DATE_FILE" ] || echo "[]" > "$TARGET_DATE_FILE"
[ -f "$STREAK_FILE" ] || echo '{"current_streak": 0, "stars_this_week": 0, "last_updated_date": "", "total_tasks": 0, "completed_tasks": 0}' > "$STREAK_FILE"

# Date 
validate_date() {
  date -d "$1" "+%F" >/dev/null 2>&1
  return $?
}

# Progress bar
progress_bar() {
  local percent=$1
  local width=20
  filled=$(echo "scale=0; ($percent * $width) / 100" | bc -l)
  filled=${filled%.*}  # Remove decimal part
  [ $filled -lt 0 ] && filled=0
  [ $filled -gt $width ] && filled=$width
  empty=$((width - filled))
  printf "[%s%s] %.3f%%" "$(printf '█%.0s' $(seq 1 $filled))" "$(printf '░%.0s' $(seq 1 $empty))" "$percent"
}

# Star reset logic
check_and_reset_stars() {
  local current_date=$(date +%F)
  local current_week=$(date +%V)
  local current_month=$(date +%m)
  jq --arg date "$current_date" --arg week "$current_week" --arg month "$current_month" '
    (if .daily_reset_date != $date then .daily_stars = 0 | .daily_reset_date = $date else . end) |
    (if .weekly_reset_week != $week and (now | strftime("%A") == "Monday") then .weekly_stars = 0 | .weekly_reset_week = $week else . end) |
    (if .monthly_reset_month != $month and (now | strftime("%d") == "01") then .monthly_stars = 0 | .monthly_reset_month = $month else . end)
  ' "$STARS_FILE" > tmp && mv tmp "$STARS_FILE"
}
# Task reset logic
check_and_reset_tasks() {
  local current_date=$(date +%F)
  local current_week=$(date +%V)
  local current_month=$(date +%m)
   # Daily reset
  if [ -f "$TODO_TUI_APP_DIR/last_day_reset" ]; then
    local last_day_reset=$(cat "$TODO_TUI_APP_DIR/last_day_reset")
    if [ "$last_day_reset" != "$current_date" ]; then
      echo "[]" > "$DAY_TASK_FILE"
      echo "$current_date" > "$TODO_TUI_APP_DIR/last_day_reset"
    fi
  else
    echo "$current_date" > "$TODO_TUI_APP_DIR/last_day_reset"
  fi
  # Weekly reset
  if [ -f "$TODO_TUI_APP_DIR/last_week_reset" ]; then
    local last_week_reset=$(cat "$TODO_TUI_APP_DIR/last_week_reset")
    if [ "$last_week_reset" != "$current_week" ] && [ "$(date +%A)" = "Monday" ]; then
      echo "[]" > "$WEEK_TASK_FILE"
      echo "$current_week" > "$TODO_TUI_APP_DIR/last_week_reset"
    fi
  else
    echo "$current_week" > "$TODO_TUI_APP_DIR/last_week_reset"
  fi
  # Monthly reset
  if [ -f "$TODO_TUI_APP_DIR/last_month_reset" ]; then
    local last_month_reset=$(cat "$TODO_TUI_APP_DIR/last_month_reset")
    if [ "$last_month_reset" != "$current_month" ] && [ "$(date +%d)" = "01" ]; then
      echo "[]" > "$MONTH_TASK_FILE"
      echo "$current_month" > "$TODO_TUI_APP_DIR/last_month_reset"
    fi
  else
    echo "$current_month" > "$TODO_TUI_APP_DIR/last_month_reset"
  fi
}

streak_window() {
  local current_streak=$(jq -r '.current_streak' "$STREAK_FILE")
  local stars=$(jq -r '.stars_this_week' "$STREAK_FILE")
  local star_display=""
  for ((i=0; i<stars && i<7; i++)); do
      star_display+="⭐"
  done
  gum style --border "$BORDER_STYLE" --border-foreground "$COLOR_ACCENT" --padding "$PADDING" --width 20 \
      "$(printf "🔥 Streak: %d\n\n%s\n%d/7" "$current_streak" "$star_display" "$stars")"
}

# streak update function
update_streak() {
  local current_date=$(date +%F)
  local last_updated=$(jq -r '.last_updated_date' "$STREAK_FILE")
  if [ "$last_updated" != "$current_date" ]; then
    local prev_total=$(jq -r '.total_tasks' "$STREAK_FILE")
    local prev_completed=$(jq -r '.completed_tasks' "$STREAK_FILE")
   if [ "$prev_total" -gt 0 ] && [ "$prev_total" -eq "$prev_completed" ]; then
      jq '.current_streak += 1 | .stars_this_week += 1' "$STREAK_FILE" > tmp && mv tmp "$STREAK_FILE"
    else
      jq '.current_streak = 0 | .stars_this_week = 0' "$STREAK_FILE" > tmp && mv tmp "$STREAK_FILE"
    fi
    jq --arg date "$current_date" \
      '.total_tasks = 0 | .completed_tasks = 0 | .last_updated_date = $date' \
      "$STREAK_FILE" > tmp && mv tmp "$STREAK_FILE"
  fi
}
# Update stars
update_stars() {
  local period=$1
  local star_field
  case $period in
    day) star_field="daily_stars" ;;
    week) star_field="weekly_stars" ;;
    month) star_field="monthly_stars" ;;
  esac
  jq --arg field "$star_field" '.[$field] += 1 | .total_stars += 1' "$STARS_FILE" > tmp && mv tmp "$STARS_FILE"
}

# Windows
reward_window() {
  check_and_reset_stars
  local daily_stars=$(jq -r '.daily_stars' "$STARS_FILE")
  local weekly_stars=$(jq -r '.weekly_stars' "$STARS_FILE")
  local monthly_stars=$(jq -r '.monthly_stars' "$STARS_FILE")
  local total_earned=$(cat "$STARS_EARNED_FILE")
  local total_tasks=$(cat "$TOTAL_TASK_FILE")
 gum style --border "$BORDER_STYLE" --border-foreground "$COLOR_ACCENT" --padding "$PADDING" --align center \
    "STARS ⭐ EARNED: 🌞 Day: $daily_stars | 📅 Week: $weekly_stars | 🌙 Month: $monthly_stars | Total Earned⭐ : $total_earned/$total_tasks"
}
calendar_window() {
  local cal_output=$(cal)
  local current_day=$(date +%d)
  cal_output=$(echo "$cal_output" | sed "s/\b$current_day\b/$(printf '\033[31m')$current_day$(printf '\033[0m')/")
  local header=$(gum style --foreground "$COLOR_ACCENT" "📅 Calendar")
  gum style --border "$BORDER_STYLE" --border-foreground "$COLOR_ACCENT" --padding "$PADDING" --width 40 \
    "$(printf "%s\n\n%s" "$header" "$cal_output")"
}
task_window() {
  local period=$1
  local file
  case $period in
    day) file="$DAY_TASK_FILE" ;;
    week) file="$WEEK_TASK_FILE" ;;
    month) file="$MONTH_TASK_FILE" ;;
  esac
  [ -f "$file" ] || echo "[]" > "$file"
  local tasks=$(jq -r '.[] | select(.completed == false) | .task' "$file" | nl -w1 -s'. ')
  local total=$(jq 'length' "$file")
  local completed=$(jq '[.[] | select(.completed)] | length' "$file")
  local progress=$((total > 0 ? completed * 100 / total : 0))
  local emoji
  case $period in
    day) emoji="🌞" ;;
    week) emoji="📅" ;;
    month) emoji="🌙" ;;
  esac
  printf "%s %s Tasks\n%s\n%s" "$emoji" "${period^}" "${tasks:-No tasks}" "$(progress_bar $progress)" | gum style --border "$BORDER_STYLE" --border-foreground "$COLOR_SECONDARY" --padding "$PADDING" --width 30
}
notes_window() {
  local notes=$(jq -r 'to_entries[] | "\(.key+1): \(if .value.type == "link" then "🔗" else "📄" end) \(.value.content)"' "$NOTES_FILE")
  printf "📝 Notes\n%s" "${notes:-No notes}" | gum style --border "$BORDER_STYLE" --border-foreground "$COLOR_SECONDARY" --padding "$PADDING" --width 80
}
countdown_window() {
  local targets=()
  local countdowns=()
  local target_count=$(jq -r 'length' "$TARGET_DATE_FILE")
  [ "$target_count" -eq 0 ] && return
  for ((i=0; i<target_count; i++)); do
    local label=$(jq -r ".[$i].label" "$TARGET_DATE_FILE")
    local target_date=$(jq -r ".[$i].date" "$TARGET_DATE_FILE")
    local start_date=$(jq -r ".[$i].start_date" "$TARGET_DATE_FILE")
     [ "$label" = "null" ] && label="Target $((i+1))"
    local current_date=$(date +%s)
    local target_seconds=$(date -d "$target_date" +%s 2>/dev/null)
    if [ $? -ne 0 ]; then
      countdowns+=("$(gum style --border "$BORDER_STYLE" --border-foreground 196 --padding "$PADDING" --width 40 "Invalid date!")")
      continue
    fi
    local days_left=$(((target_seconds - current_date) / 86400))
    if [ $days_left -ge 0 ]; then
      local start_seconds=$(date -d "$start_date" +%s)
      local total_seconds=$((target_seconds - start_seconds))
      local elapsed_seconds=$((current_date - start_seconds))
      local progress
      if [ $total_seconds -gt 0 ]; then
        local elapsed_percent=$(echo "scale=3; ($elapsed_seconds / $total_seconds) * 100" | bc -l)
        progress=$(echo "scale=3; 100 - $elapsed_percent" | bc -l)
        progress=$(printf "%.3f" $progress)
      else
        progress="0.000"
      fi
      countdowns+=("$(gum style --border "$BORDER_STYLE" --border-foreground "$COLOR_ACCENT" --padding "$PADDING" --width 40 \
        "$(printf "%s\n%s\n%d days left\n%s" "$label" "$target_date" "$days_left" "$(progress_bar $progress)")")")
    else
      countdowns+=("$(gum style --border "$BORDER_STYLE" --border-foreground 196 --padding "$PADDING" --width 40 "Target passed!")")
    fi
  done
  gum join --horizontal "${countdowns[@]}"
}

# Tasks functions
add_task_dialog() {
  local period=$(gum choose --header "Select period" day week month)
  [ -z "$period" ] && return
  gum style --foreground "$COLOR_ACCENT" "Enter tasks separated by \| (e.g.: Math homework\|Gym\|Call mom)"
  local input_tasks=$(gum input --placeholder "Add multiple tasks (use | separator)")
  [ -z "$input_tasks" ] && return
  IFS='|' read -ra tasks <<< "$input_tasks"
  for task in "${tasks[@]}"; do
    task=$(echo "$task" | xargs)
    [ -z "$task" ] && continue
    gum confirm "Add to $period: '$task'?" && {
      local file
      case $period in
        day) file="$DAY_TASK_FILE" ;;
        week) file="$WEEK_TASK_FILE" ;;
        month) file="$MONTH_TASK_FILE" ;;
      esac
      jq --arg task "$task" '. + [{"task": $task, "completed": false}]' "$file" > tmp && mv tmp "$file"
      echo "date:$(date +%d/%m/%Y):$period:$task" >> "$TASK_HISTORY_FILE"
      local current_total=$(cat "$TOTAL_TASK_FILE")
      echo $((current_total + 1)) > "$TOTAL_TASK_FILE"
      if [ "$period" = "day" ]; then
        jq '.total_tasks += 1' "$STREAK_FILE" > tmp && mv tmp "$STREAK_FILE"
      fi
      gum style --foreground "$COLOR_ACCENT" "/🫵️ YOU CAN DO THIS: $task"
    }
  done
}
remove_task_dialog() {
  local period=$(gum choose --header "Select period" day week month)
  [ -z "$period" ] && return
  local file
  case $period in
    day) file="$DAY_TASK_FILE" ;;
    week) file="$WEEK_TASK_FILE" ;;
    month) file="$MONTH_TASK_FILE" ;;
  esac
  mapfile -t task_entries < <(jq -r 'to_entries[] | select(.value.completed == false) | "\(.key) \(.value.task)"' "$file")
  [ ${#task_entries[@]} -eq 0 ] && { gum confirm "No tasks in $period period." --affirmative "OK"; return; }
  display_list=()
  original_indices=()
  for entry in "${task_entries[@]}"; do
    idx=$(echo "$entry" | cut -d' ' -f1)
    task=$(echo "$entry" | cut -d' ' -f2-)
    display_list+=("$((${#display_list[@]} + 1)). $task")
    original_indices+=("$idx")
  done
  local selected=$(gum choose --header "Select task to remove" "${display_list[@]}")
  [ -z "$selected" ] && return
  local display_num=$(echo "$selected" | cut -d'.' -f1)
  local task_index=${original_indices[$((display_num - 1))]}
  gum confirm "Remove: $(echo "$selected" | cut -d'.' -f2- | xargs)?" && {
    jq --argjson idx "$task_index" 'del(.[$idx])' "$file" > tmp && mv tmp "$file"
    echo $(( $(cat "$TOTAL_TASK_FILE") - 1 )) > "$TOTAL_TASK_FILE"
    if [ "$period" = "day" ]; then
      jq '.total_tasks -= 1' "$STREAK_FILE" > tmp && mv tmp "$STREAK_FILE"
    fi
    gum style --foreground "$COLOR_ACCENT" "🗑️ Task removed from $period."
  }
}
complete_task_dialog() {
  local period=$(gum choose --header "Select period" day week month)
  [ -z "$period" ] && return
  local file
  case $period in
    day) file="$DAY_TASK_FILE" ;;
    week) file="$WEEK_TASK_FILE" ;;
    month) file="$MONTH_TASK_FILE" ;;
  esac
  mapfile -t task_entries < <(jq -r 'to_entries[] | select(.value.completed == false) | "\(.key) \(.value.task)"' "$file")
  [ ${#task_entries[@]} -eq 0 ] && { gum confirm "No incomplete tasks in $period period." --affirmative "OK"; return; }
  display_list=()
  original_indices=()
  for entry in "${task_entries[@]}"; do
    idx=$(echo "$entry" | cut -d' ' -f1)
    task=$(echo "$entry" | cut -d' ' -f2-)
    display_list+=("$((${#display_list[@]} + 1)). $task")
    original_indices+=("$idx")
  done
  local selected=$(gum choose --header "Select task to complete" "${display_list[@]}")
  [ -z "$selected" ] && return
  local display_num=$(echo "$selected" | cut -d'.' -f1)
  local task_index=${original_indices[$((display_num - 1))]}
  local task_content=$(echo "$selected" | cut -d'.' -f2- | xargs)
  gum confirm "Complete: $task_content?" && {
    jq --argjson idx "$task_index" '.[$idx].completed = true' "$file" > tmp && mv tmp "$file"
    update_stars "$period"
    echo $(( $(cat "$STARS_EARNED_FILE") + 1 )) > "$STARS_EARNED_FILE"
   if [ "$period" = "day" ]; then
      jq '.completed_tasks += 1' "$STREAK_FILE" > tmp && mv tmp "$STREAK_FILE"
      update_streak  # Check if all daily tasks are completed
    fi
    gum style --foreground "$COLOR_ACCENT" "✅ Task completed! ⭐ +1"    
  }
}

# Notes functions
add_note_dialog() {
  local type=$(gum choose --header "Note type" text link)
  [ -z "$type" ] && return
  local content=$(gum input --placeholder "Enter ${type} (URL if link)")
  [ -z "$content" ] && return
  
  if [ "$type" = "link" ] && [[ ! "$content" =~ ^https?:// ]]; then
    gum style --foreground 196 "Invalid URL! Must start with http:// or https://"
    return
  fi

  gum confirm "Add ${type} note: ${content}" && {
    local next_id=$(jq 'map(.id) | max + 1' "$NOTES_FILE")
    [ "$next_id" = "null" ] && next_id=1
    jq --arg id "$next_id" --arg type "$type" --arg content "$content" \
      '. + [{"id": ($id | tonumber), "type": $type, "content": $content}]' \
      "$NOTES_FILE" > tmp && mv tmp "$NOTES_FILE"
    gum style --foreground "$COLOR_ACCENT" "Note added."
  }
}
edit_note_dialog() {
  local notes=$(jq -r '.[] | "\(.id): [\(.type)] \(.content)"' "$NOTES_FILE")
  [ -z "$notes" ] && { gum confirm "No notes available." --affirmative "OK"; return; }
  mapfile -t note_list < <(echo "$notes")
  local selected=$(gum choose --header "Select note to edit" "${note_list[@]}")
  [ -z "$selected" ] && return
  local note_id=$(echo "$selected" | cut -d':' -f1)
  local old_content=$(jq -r ".[] | select(.id == $note_id).content" "$NOTES_FILE")
  local new_content=$(gum input --placeholder "Edit content" --value "$old_content")
  gum confirm "Update note?" && {
    jq --arg id "$note_id" --arg content "$new_content" \
      '(.[] | select(.id == ($id | tonumber)).content) |= $content' \
      "$NOTES_FILE" > tmp && mv tmp "$NOTES_FILE"
    gum style --foreground "$COLOR_ACCENT" "Note updated."
  }
}
delete_note_dialog() {
  local notes=$(jq -r 'to_entries[] | "\(.key+1): \(.value.type) \(.value.content)"' "$NOTES_FILE")
  [ -z "$notes" ] && { gum confirm "No notes available." --affirmative "OK"; return; }
  mapfile -t note_list < <(echo "$notes")
  local selected=$(gum choose --header "Select note to delete" "${note_list[@]}")
  [ -z "$selected" ] && return
  local note_index=$(echo "$selected" | cut -d':' -f1)
  note_index=$((note_index - 1))
  gum confirm "Delete note: $(echo "$selected" | cut -d':' -f2- | xargs)?" && {
    jq --argjson idx "$note_index" 'del(.[$idx])' "$NOTES_FILE" | jq 'to_entries | map(.value)' > tmp && mv tmp "$NOTES_FILE"
    gum style --foreground "$COLOR_ACCENT" "Note deleted."
  }
}
# Target date functions
set_target_date_dialog() {
  local label=$(gum input --placeholder "Enter countdown label")
  [ -z "$label" ] && return
  local date=$(gum input --placeholder "Enter target date (YYYY-MM-DD)")
  [ -z "$date" ] && return
  if ! validate_date "$date"; then
    gum style --foreground 196 "Invalid date format!"
    return
  fi
  gum confirm "Add countdown '$label' to $date?" && {
    jq --arg label "$label" --arg date "$date" --arg start "$(date +%F)" \
      '. += [{"label": $label, "date": $date, "start_date": $start}]' \
      "$TARGET_DATE_FILE" > tmp && mv tmp "$TARGET_DATE_FILE"
    gum style --foreground "$COLOR_ACCENT" "Countdown added!"
  }
}
delete_target_date_dialog() {
  local targets=$(jq -r 'to_entries[] | "\(.key+1): \(.value.label) (\(.value.date))"' "$TARGET_DATE_FILE")
  [ -z "$targets" ] && { gum style --foreground "$COLOR_ACCENT" "No targets set."; return; }
  
  mapfile -t target_list < <(echo "$targets")
  local selected=$(gum choose --header "Select target to delete" "${target_list[@]}")
  [ -z "$selected" ] && return
  
  local target_index=$(echo "$selected" | cut -d':' -f1)
  target_index=$((target_index - 1))
  
  gum confirm "Delete target: $(echo "$selected" | cut -d':' -f2- | xargs)?" && {
    jq --argjson idx "$target_index" 'del(.[$idx])' "$TARGET_DATE_FILE" > tmp && mv tmp "$TARGET_DATE_FILE"
    gum style --foreground "$COLOR_ACCENT" "Target deleted."
  }
}
# interface
main_interface() {
  while true; do
    clear
    check_and_reset_tasks
    update_streak
    gum join --vertical \
      "$(reward_window)" \
      "$(gum join --horizontal \
        "$(calendar_window)" \
        "$(notes_window)" \
      )" \
      "$(gum join --horizontal \
        "$(streak_window)" \
        "$(countdown_window)" \
      )" \
      "$(gum join --horizontal \
        "$(task_window day)" \
        "$(task_window week)" \
        "$(task_window month)" \
      )"
    action=$(gum choose --header " " --header.foreground "$COLOR_ACCENT" \
      "Add Task" "Remove Task" "Complete Task" \
      "Add Note" "Edit Note" "Delete Note" \
      "Set Target Date" "Delete Target Date" "Exit")
    case $action in
      "Add Task") add_task_dialog ;;
      "Remove Task") remove_task_dialog ;;
      "Complete Task") complete_task_dialog ;;
      "Add Note") add_note_dialog ;;
      "Edit Note") edit_note_dialog ;;
      "Delete Note") delete_note_dialog ;;
      "Set Target Date") set_target_date_dialog ;;
      "Delete Target Date") delete_target_date_dialog ;;
      "Exit") exit 0 ;;
    esac
  done
}
# last
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main_interface
fi
