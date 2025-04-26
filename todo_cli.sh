#!/usr/bin/env bash
# todocli - CLI interface for todo.sh 

TODO_CLI_APP_DIR="$HOME/.todo_config"
TODO_FILE="$HOME/.todo/todo_tui.sh"

# Define file paths
DAY_TASK_FILE="$TODO_CLI_APP_DIR/day_tasks.json"
WEEK_TASK_FILE="$TODO_CLI_APP_DIR/week_tasks.json"
MONTH_TASK_FILE="$TODO_CLI_APP_DIR/month_tasks.json"
NOTES_FILE="$TODO_CLI_APP_DIR/notes.json"
TARGET_DATE_FILE="$TODO_CLI_APP_DIR/target_dates.json"
STARS_FILE="$TODO_CLI_APP_DIR/stars.json"
TOTAL_TASK_FILE="$TODO_CLI_APP_DIR/total_tasks.txt"
STARS_EARNED_FILE="$TODO_CLI_APP_DIR/stars_earned.txt"
STREAK_FILE="$TODO_CLI_APP_DIR/streak.json"
TASK_HISTORY_FILE="$TODO_CLI_APP_DIR/task_history.txt"

# Initialize files
for file in "$DAY_TASK_FILE" "$WEEK_TASK_FILE" "$MONTH_TASK_FILE" "$NOTES_FILE" "$TARGET_DATE_FILE"; do
  [ -f "$file" ] || echo "[]" > "$file"
done
[ -f "$STARS_FILE" ] || echo '{"daily_stars": 0, "daily_reset_date": "", "weekly_stars": 0, "weekly_reset_week": "", "monthly_stars": 0, "monthly_reset_month": "", "total_stars": 0}' > "$STARS_FILE"
[ -f "$TOTAL_TASK_FILE" ] || echo "0" > "$TOTAL_TASK_FILE"
[ -f "$STARS_EARNED_FILE" ] || echo "0" > "$STARS_EARNED_FILE"
[ -f "$STREAK_FILE" ] || echo '{"current_streak": 0, "stars_this_week": 0, "last_updated_date": "", "total_tasks": 0, "completed_tasks": 0}' > "$STREAK_FILE"
[ -f "$TASK_HISTORY_FILE" ] || touch "$TASK_HISTORY_FILE"

show_help() {
  echo "Usage:"
  echo "  todocli [command] [options]"
  echo ""
  echo "📌 Basic Commands:"
  echo "  todocli --help                 Show this help message"
  echo ""
  echo "📝 Task Operations:"
  echo "  todocli add task --period [day/week/month] --tasks \"Task1|Task2\""
  echo "  todocli remove task --period [day/week/month] --task \"Task Name\""
  echo "  todocli complete task --period [day/week/month] --task \"Task Name\""
  echo ""
  echo "📚 Note Operations:"
  echo "  todocli add note --type [text/link] --content \"Content\""
  echo "  todocli edit note              Select and edit a note"
  echo "  todocli delete note            Select and delete a note"
  echo ""
  echo "🎯 Target Dates:"
  echo "  todocli set-target \"Label\" \"YYYY-MM-DD\""
  echo "  todocli remove target date     Select and delete a target date"
  echo ""
  echo "🔍 Show Commands:"
  echo "  todocli show day task          List daily tasks"
  echo "  todocli show week task         List weekly tasks"
  echo "  todocli show month task        List monthly tasks"
  echo "  todocli show all tasks         List all tasks"
  echo "  todocli show notes             List all notes"
  echo "  todocli show streak            Show current streak"
  echo "  todocli show target dates      Show target countdowns"
  echo ""
  echo "🔍 Examples:"
  echo "  todocli add task --period day --tasks \"Gym|Math homework\""
  echo "  todocli complete task --period day --task \"Gym\""
  echo "  todocli show week task"
  echo "  todocli set-target \"Exam\" \"2023-12-15\""
}

clean_exit() {
  tput sgr0 2>/dev/null || true
  exit ${1:-0}
}

handle_error() {
  echo "❌ Error: $1" >&2
  show_help >&2
  clean_exit 1
}

[ -f "$TODO_FILE" ] || handle_error "Missing todo.sh file"
source "$TODO_FILE" >/dev/null 2>&1 || handle_error "Failed to source todo.sh"

# JSON validation helper
_check_json() {
  local file="$1"
  if ! jq empty "$file" >/dev/null 2>&1; then
    echo "⚠️  Invalid JSON in $file. Resetting..."
    case $(basename "$file") in
      notes.json|target_dates.json) echo "[]" > "$file" ;;
      stars.json) echo '{"daily_stars":0,"daily_reset_date":"","weekly_stars":0,"weekly_reset_week":"","monthly_stars":0,"monthly_reset_month":"","total_stars":0}' > "$file" ;;
    esac
  fi
}

# Note functions
show_notes() {
  echo "📝 Notes:"
  jq -r 'to_entries[] | "  \(.key+1). \(if .value.type == "link" then "🔗" else "📄" end) \(.value.content)"' "$NOTES_FILE"
}

select_note() {
  local notes=$(jq -r 'to_entries[] | "\(.key+1)"' "$NOTES_FILE")
  [ -z "$notes" ] && { echo "No notes available"; return 1; }
  
  show_notes
  read -p "Enter note number (1-${#notes[@]}): " num
  [[ "$num" =~ ^[0-9]+$ ]] || { echo "Invalid number"; return 1; }
  [ "$num" -ge 1 ] && [ "$num" -le "${#notes[@]}" ] || { echo "Invalid range"; return 1; }
  echo $((num - 1))
}

add_note() {
  local type="$1"
  local content="$2"
  local next_id=$(jq '[.[] | .id] | if length > 0 then max + 1 else 1 end' "$NOTES_FILE")
  jq --arg id "$next_id" --arg type "$type" --arg content "$content" \
    '. + [{"id": ($id | tonumber), "type": $type, "content": $content}]' \
    "$NOTES_FILE" > tmp && mv tmp "$NOTES_FILE"
  echo "✅ Note added: [$type] $content"
}

delete_note() {
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

edit_note() {
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

# Target date functions
set_target() {
  local label="$1"
  local date="$2"
  if ! validate_date "$date"; then
    handle_error "Invalid date format: $date"
  fi
  jq --arg label "$label" --arg date "$date" --arg start "$(date +%F)" \
    '. += [{"label": $label, "date": $date, "start_date": $start}]' \
    "$TARGET_DATE_FILE" > tmp && mv tmp "$TARGET_DATE_FILE"
  echo "🎯 Target set: $label on $date"
}

select_target() {
  local target_count=$(jq 'length' "$TARGET_DATE_FILE")
  if [ "$target_count" -eq 0 ]; then
    echo "No target dates available."
    return 1
  fi
  echo "Available target dates:"
  jq -r 'to_entries[] | "\(.key + 1). \(.value.label): \(.value.date)"' "$TARGET_DATE_FILE"
  read -p "Enter the number of the target date: " num
  if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt "$target_count" ]; then
    echo "Invalid selection."
    return 1
  fi
  local index=$((num - 1))
  local selected_label=$(jq -r ".[$index].label" "$TARGET_DATE_FILE")
  echo "$selected_label"
}

show_target_dates() {
  local targets=$(jq -r '.[] | "  🎯 \(.label): \(.date) (\((.date | strptime("%Y-%m-%d") | mktime - now) / 86400 | floor) days left)"' "$TARGET_DATE_FILE")
  if [ -z "$targets" ]; then
    echo "No target dates set."
  else
    echo "⏳ Target Dates:"
    echo "$targets"
  fi
}

delete_target() {
  _check_json "$TARGET_DATE_FILE"
  local target_count=$(jq 'length' "$TARGET_DATE_FILE")
  [ "$target_count" -eq 0 ] && { echo "No targets set"; return; }
  
  echo "Target dates:"
  jq -r 'to_entries[] | "\(.key + 1)|\(.value.label)|\(.value.date)"' "$TARGET_DATE_FILE" | column -t -s "|" -N "#,Label,Date"
  read -p "Enter target number: " num
  
  [[ "$num" =~ ^[0-9]+$ ]] || { echo "Invalid number"; return; }
  [ "$num" -ge 1 ] && [ "$num" -le "$target_count" ] || { echo "Invalid range"; return; }
  
  local index=$((num - 1))
  local label=$(jq -r ".[$index].label" "$TARGET_DATE_FILE")
  
  read -p "Delete 『$label』? (y/n): " confirm
  [[ "$confirm" == [yY] ]] || { echo "Cancelled"; return; }
  
  jq "del(.[$index])" "$TARGET_DATE_FILE" > tmp && mv tmp "$TARGET_DATE_FILE"
  echo "🗑️ Target deleted"
}

# Task functions
_get_task_id() {
  local file="$1"
  local task_name="$2"
  jq -r --arg name "$task_name" '
    to_entries[] | 
    select(.value.task == $name and .value.completed == false) | 
    .key' "$file" | tr -d '\n'
}

_validate_single() {
  local ids=($1)
  local file="$2"
  [ ${#ids[@]} -eq 0 ] && {
    echo "🔍 No matches! Current entries:"
    jq -r '.[] | select(.completed == false) | .task' "$file"
    clean_exit 1
  }
  [ ${#ids[@]} -gt 1 ] && handle_error "Multiple matches found"
}

add_task() {
  local period="$1"
  local tasks="$2"
  local file
  
  case $period in
    day) file="$DAY_TASK_FILE";;
    week) file="$WEEK_TASK_FILE";;
    month) file="$MONTH_TASK_FILE";;
    *) handle_error "Invalid period";;
  esac

  IFS='|' read -ra task_array <<< "$tasks"
  for task in "${task_array[@]}"; do
    task=$(echo "$task" | xargs)
    [ -z "$task" ] && continue
    
    jq --arg task "$task" '. + [{"task": $task, "completed": false}]' "$file" > tmp && mv tmp "$file"
    echo "✅ Added to $period: '$task'"
    echo $(( $(cat "$TOTAL_TASK_FILE") + 1 )) > "$TOTAL_TASK_FILE"
    [ "$period" = "day" ] && jq '.total_tasks += 1' "$STREAK_FILE" > tmp && mv tmp "$STREAK_FILE"
  done
}

remove_task() {
  local period="$1"
  local task_name="$2"
  local file
  
  case $period in
    day) file="$DAY_TASK_FILE";;
    week) file="$WEEK_TASK_FILE";;
    month) file="$MONTH_TASK_FILE";;
    *) handle_error "Invalid period";;
  esac

  task_ids=$(_get_task_id "$file" "$task_name")
  _validate_single "$task_ids" "$file"
  
  jq --argjson idx "${task_ids}" 'del(.[$idx])' "$file" > tmp && mv tmp "$file"
  echo $(( $(cat "$TOTAL_TASK_FILE") - 1 )) > "$TOTAL_TASK_FILE"
  [ "$period" = "day" ] && jq '.total_tasks -= 1' "$STREAK_FILE" > tmp && mv tmp "$STREAK_FILE"
  echo "🗑️ Removed '$task_name' from $period tasks"
}

complete_task() {
  local period="$1"
  local task_name="$2"
  local file
  
  case $period in
    day) file="$DAY_TASK_FILE";;
    week) file="$WEEK_TASK_FILE";;
    month) file="$MONTH_TASK_FILE";;
    *) handle_error "Invalid period";;
  esac

  task_ids=$(_get_task_id "$file" "$task_name")
  _validate_single "$task_ids" "$file"

  jq --argjson idx "${task_ids}" '.[$idx].completed = true' "$file" > tmp && mv tmp "$file"
  update_stars "$period"
  echo $(( $(cat "$STARS_EARNED_FILE") + 1 )) > "$STARS_EARNED_FILE"
  [ "$period" = "day" ] && {
    jq '.completed_tasks += 1' "$STREAK_FILE" > tmp && mv tmp "$STREAK_FILE"
    update_streak
  }
  echo "✅ Completed '$task_name' ⭐"
}

show_tasks() {
  local period="$1"
  case $period in
    day) file="$DAY_TASK_FILE"; emoji="🌞";;
    week) file="$WEEK_TASK_FILE"; emoji="📅";;
    month) file="$MONTH_TASK_FILE"; emoji="🌙";;
    all)
      echo "📋 All Tasks"
      echo "🌞 Daily:"; show_tasks "day" | tail -n +2
      echo "📅 Weekly:"; show_tasks "week" | tail -n +2
      echo "🌙 Monthly:"; show_tasks "month" | tail -n +2
      return
      ;;
  esac

  echo "${emoji} ${period^} Tasks:"
  jq -r '.[] | select(.completed == false) | "  - \(.task)"' "$file" | nl -w2 -s '. '
  echo "➖ Total: $(jq 'length' "$file") | ✅ Completed: $(jq '[.[] | select(.completed)] | length' "$file")"
}

show_streak() {
  echo "🔥 Streak:"
  echo "  Days: $(jq -r '.current_streak' "$STREAK_FILE")"
  echo "  ⭐ This Week: $(jq -r '.stars_this_week' "$STREAK_FILE")/7"
  echo "  ✅ Tasks: $(jq -r '.completed_tasks' "$STREAK_FILE")/$(jq -r '.total_tasks' "$STREAK_FILE")"
}


parse_arguments() {
  case $1 in
    --help|-h|help)
      show_help
      clean_exit 0
      ;;

    add)
      case $2 in
        task)
          period=""
          tasks=""
          while [[ $# -gt 2 ]]; do
            case $3 in
              --period) period="$4"; shift 2;;
              --tasks) tasks="${@:4}"; break;;
              *) shift;;
            esac
          done
          [ -z "$period" ] && handle_error "Missing --period"
          [ -z "$tasks" ] && handle_error "Missing --tasks"
          add_task "$period" "$tasks"
          ;;

        note)
          type=""
          content=""
          while [[ $# -gt 2 ]]; do
            case $3 in
              --type) type="$4"; shift 2;;
              --content) content="${@:4}"; break;;
              *) shift;;
            esac
          done
          [ -z "$type" ] && handle_error "Missing --type"
          [ -z "$content" ] && handle_error "Missing --content"
          add_note "$type" "$content"
          ;;

        *)
          handle_error "Invalid add command"
          ;;
      esac
      ;;

    edit)
      case $2 in
        note)
          edit_note
          ;;
        *)
          handle_error "Invalid edit command"
          ;;
      esac
      ;;

    remove|delete)
      case $2 in
        task)
          period=""
          task=""
          while [[ $# -gt 2 ]]; do
            case $3 in
              --period) period="$4"; shift 2;;
              --task) task="${@:4}"; break;;
              *) shift;;
            esac
          done
          [ -z "$period" ] && handle_error "Missing --period"
          [ -z "$task" ] && handle_error "Missing --task"
          remove_task "$period" "$task"
          ;;

        note)
          delete_note
          ;;

        target)
          [ "$3" != "date" ] && handle_error "Invalid command, use 'remove target date'"
          delete_target
          ;;

        *)
          handle_error "Invalid remove command"
          ;;
      esac
      ;;

    complete)
      [ "$2" != "task" ] && handle_error "Invalid complete command"
      period=""
      task=""
      while [[ $# -gt 2 ]]; do
        case $3 in
          --period) period="$4"; shift 2;;
          --task) task="${@:4}"; break;;
          *) shift;;
        esac
      done
      [ -z "$period" ] && handle_error "Missing --period"
      [ -z "$task" ] && handle_error "Missing --task"
      complete_task "$period" "$task"
      ;;

    show)
      case $2 in
        day)
          [ "$3" = "task" ] && show_tasks "day" || handle_error "Invalid show command"
          ;;
        week)
          [ "$3" = "task" ] && show_tasks "week" || handle_error "Invalid show command"
          ;;
        month)
          [ "$3" = "task" ] && show_tasks "month" || handle_error "Invalid show command"
          ;;
        all)
          [ "$3" = "tasks" ] && show_tasks "all" || handle_error "Invalid show command"
          ;;
        notes)
          show_notes
          ;;
        streak)
          show_streak
          ;;
        target)
          [ "$3" = "dates" ] && show_target_dates || handle_error "Invalid show command"
          ;;
        *)
          handle_error "Invalid show command"
          ;;
      esac
      clean_exit 0
      ;;

    set-target)
      [ -z "$2" ] && handle_error "Missing target label"
      [ -z "$3" ] && handle_error "Missing target date"
      set_target "$2" "$3"
      ;;

    reset-notes)
      reset_notes
      ;;

    reset-targets)
      reset_targets
      ;;

    *)
      handle_error "Unknown command: $1"
      ;;
  esac
}

trap 'clean_exit 1' INT TERM
parse_arguments "$@"
check_and_reset_stars
check_and_reset_tasks
clean_exit 0
