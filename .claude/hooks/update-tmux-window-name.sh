#!/bin/bash

# Smart tmux window name updater with debouncing and context awareness

# Safety check: Exit immediately if this hook is being called from within itself
# This prevents infinite loops when this script calls Claude CLI
if [ "$CLAUDE_TMUX_HOOK_ACTIVE" = "1" ]; then
  # Just pass through the input unchanged and exit
  cat
  exit 0
fi

# Claude CLI path
CLAUDE_BIN="$HOME/.claude/local/node_modules/.bin/claude"

# Read the input JSON
INPUT=$(cat)

# Pass through the input unchanged
echo "$INPUT"

# Only proceed if we're in a tmux session
if [ -z "$TMUX" ]; then
  exit 0
fi

# Setup logging with locking (only when DEBUG=1)
LOG_FILE="/tmp/claude-tmux-hook.log"
LOG_LOCK="/tmp/claude-tmux-hook.lock"
# DEBUG="1"

# Helper function for thread-safe logging
log() {
  if [ "$DEBUG" = "1" ]; then
    (
      flock -x 200
      echo "$1" >>"$LOG_FILE"
    ) 200>"$LOG_LOCK"
  fi
}

log "========== $(date '+%Y-%m-%d %H:%M:%S') =========="

# Parse all needed fields separately to handle spaces properly
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)

log "Event: $HOOK_EVENT | Session: $SESSION_ID | Tool: $TOOL_NAME"

# Skip if no session_id
if [ -z "$SESSION_ID" ] || [ "$SESSION_ID" = "null" ]; then
  log "Skipping: No session_id"
  exit 0
fi

# Create session-specific event storage
SESSION_DIR="/tmp/claude-session-$SESSION_ID"
EVENTS_FILE="$SESSION_DIR/events.log"
STATE_FILE="$SESSION_DIR/state"
LOCK_FILE="$SESSION_DIR/hook.lock"
PID_FILE="$SESSION_DIR/claude_call.pid"

mkdir -p "$SESSION_DIR"

# Helper function to cancel any existing Claude API call
cancel_existing_call() {
  if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
      log "Canceling existing Claude call (PID: $OLD_PID)"
      kill "$OLD_PID" 2>/dev/null
    fi
    rm -f "$PID_FILE"
  fi
}

# Track current session for this tmux window
TMUX_PANE=$(tmux display-message -p '#{pane_id}' 2>/dev/null)
TMUX_WINDOW=$(tmux display-message -p '#{window_id}' 2>/dev/null)
CURRENT_SESSION_FILE="/tmp/claude-current-session-$TMUX_PANE"

log "Captured window: $TMUX_WINDOW (pane: $TMUX_PANE)"

# Initialize state if it doesn't exist (with lock)
(
  flock -x 200
  if [ ! -f "$STATE_FILE" ]; then
    echo "0" >"$STATE_FILE" # 0 means first message not set yet
  fi
) 200>"$LOCK_FILE"

# Read state outside the subshell
FIRST_MESSAGE_SET=$(cat "$STATE_FILE" 2>/dev/null || echo "0")

# Extract relevant data based on hook type
case "$HOOK_EVENT" in
"UserPromptSubmit")
  # Update current session for this tmux window
  echo "$SESSION_ID" >"$CURRENT_SESSION_FILE"
  log "Updated current session to: $SESSION_ID (pane: $TMUX_PANE)"

  # Skip if this is a recursion from our own summarization
  if echo "$PROMPT" | grep -q "^Based on this user request, generate a concise sentence"; then
    log "Skipping: recursion detected (summarization prompt)"
    exit 0
  fi

  # Truncate prompt to first 100 chars
  PROMPT_SHORT=$(echo "$PROMPT" | head -c 100 | tr '\n' ' ')
  EVENT_DATA="msg: $PROMPT_SHORT"

  log "UserPrompt: $PROMPT_SHORT"
  log "FIRST_MESSAGE_SET=$FIRST_MESSAGE_SET"

  # First message sets the window name (with lock to prevent race)
  if [ "$FIRST_MESSAGE_SET" = "0" ]; then
    (
      flock -x 200

      # Double-check after acquiring lock
      FIRST_MESSAGE_SET=$(cat "$STATE_FILE")
      if [ "$FIRST_MESSAGE_SET" = "0" ]; then
        # Mark first message as set immediately
        echo "1" >"$STATE_FILE"
        log "Setting first message, marking state=1"

        PROMPT_LENGTH=${#PROMPT}
        log "Prompt length: $PROMPT_LENGTH chars"

        # If prompt is longer than 250 chars, use Claude to summarize (in background)
        if [ $PROMPT_LENGTH -gt 250 ]; then
          log "Long prompt, using Claude to summarize (background)"
          # Cancel any existing Claude call first
          cancel_existing_call
          # Background the API call to avoid blocking
          (
            log "CLAUDE_API_CALL_START $(date '+%Y-%m-%d %H:%M:%S.%3N') Type=FirstMessage"

            CLAUDE_PROMPT="Based on this user request, generate a concise sentence (max 150 chars) describing what this session is for. Output ONLY the sentence in lowercase, no punctuation.

User request:
$PROMPT

Generate summary:"

            SUMMARY=$(echo "$CLAUDE_PROMPT" | CLAUDE_TMUX_HOOK_ACTIVE=1 timeout 10s "$CLAUDE_BIN" --setting-sources "" 2>&1 | tee -a "$LOG_FILE" | head -n 1 | tr -d '\n' | tr '[:upper:]' '[:lower:]' | cut -c 1-142)

            log "CLAUDE_API_CALL_END $(date '+%Y-%m-%d %H:%M:%S.%3N') Type=FirstMessage"

            if [ -n "$SUMMARY" ]; then
              log "AI Summary: $SUMMARY"
              tmux rename-window -t "$TMUX_WINDOW" "claude: $SUMMARY" 2>/dev/null
              log "Window renamed to: claude: $SUMMARY (window: $TMUX_WINDOW)"
            fi
          ) &
          echo $! >"$PID_FILE"
          log "Started Claude call with PID: $!"
        else
          # Just use the prompt directly, truncate to fit
          SUMMARY=$(echo "$PROMPT" | cut -c 1-142)
          log "Short prompt, using directly: $SUMMARY"
          tmux rename-window -t "$TMUX_WINDOW" "claude: $SUMMARY" 2>/dev/null
          log "Window renamed to: claude: $SUMMARY (window: $TMUX_WINDOW)"
        fi
      fi
    ) 200>"$LOCK_FILE"
  fi
  ;;
"PreToolUse")
  log "PreToolUse for tool: $TOOL_NAME"

  # Parse tool params separately to handle spaces properly
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
  DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // ""' 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
  PATTERN=$(echo "$INPUT" | jq -r '.tool_input.pattern // ""' 2>/dev/null)

  # Extract specific fields based on tool type
  case "$TOOL_NAME" in
  "Bash")
    if [ -n "$DESCRIPTION" ]; then
      EVENT_DATA="Bash: $DESCRIPTION"
    else
      # Truncate command to 80 chars
      COMMAND_SHORT=$(echo "$COMMAND" | head -c 80)
      EVENT_DATA="Bash: $COMMAND_SHORT"
    fi
    ;;
  "Read")
    FILENAME=$(basename "$FILE_PATH")
    EVENT_DATA="Read: $FILENAME"
    ;;
  "Edit" | "Write")
    FILENAME=$(basename "$FILE_PATH")
    EVENT_DATA="$TOOL_NAME: $FILENAME"
    ;;
  "Grep" | "Glob")
    EVENT_DATA="$TOOL_NAME: $PATTERN"
    ;;
  *)
    EVENT_DATA="$TOOL_NAME"
    ;;
  esac
  ;;
"PostToolUse")
  # Skip PostToolUse events to reduce clutter
  exit 0
  ;;
"Stop")
  log "Stop event received, FIRST_MESSAGE_SET=$FIRST_MESSAGE_SET"

  # Skip if first message not set
  if [ "$FIRST_MESSAGE_SET" != "1" ]; then
    log "Skipping Stop: first message not set"
    exit 0
  fi

  # Cancel any existing Claude call first
  cancel_existing_call

  # Background the entire update process to avoid blocking
  (
    # Read recent events (last 20 lines)
    RECENT_EVENTS=$(tail -n 20 "$EVENTS_FILE" 2>/dev/null)

    log "Recent events for summary:"
    log "$RECENT_EVENTS"

    # Skip if no events
    if [ -z "$RECENT_EVENTS" ]; then
      log "Skipping Stop: no recent events"
      exit 0
    fi

    # Generate updated summary using Claude
    CLAUDE_PROMPT="Based on these recent activities, generate a concise sentence (max 150 chars) describing what this session is for. Output ONLY the sentence in lowercase, no punctuation.

Recent activities:
$RECENT_EVENTS

Generate summary:"

    log "Calling Claude API for summary update..."
    log "CLAUDE_API_CALL_START $(date '+%Y-%m-%d %H:%M:%S.%3N') Type=StopEvent"
    SUMMARY=$(echo "$CLAUDE_PROMPT" | CLAUDE_TMUX_HOOK_ACTIVE=1 timeout 10s "$CLAUDE_BIN" --setting-sources "" 2>&1 | tee -a "$LOG_FILE" | head -n 1 | tr -d '\n' | tr '[:upper:]' '[:lower:]' | cut -c 1-142)
    log "CLAUDE_API_CALL_END $(date '+%Y-%m-%d %H:%M:%S.%3N') Type=StopEvent"

    # Update if valid summary
    if [ -n "$SUMMARY" ]; then
      log "Stop event summary: $SUMMARY"
      tmux rename-window -t "$TMUX_WINDOW" "claude: $SUMMARY" 2>/dev/null
      log "Window renamed to: claude: $SUMMARY (window: $TMUX_WINDOW)"
      log "Clearing events file"
      >"$EVENTS_FILE"
    else
      log "No summary generated, skipping window rename"
    fi
  ) &
  echo $! >"$PID_FILE"
  log "Started Claude call with PID: $!"

  exit 0
  ;;
*)
  # Skip other events
  exit 0
  ;;
esac

# Append event to events file (for UserPromptSubmit and PreToolUse) with lock
if [ -n "$EVENT_DATA" ]; then
  log "Appending to events file: $EVENT_DATA"
  (
    flock -x 200
    echo "$EVENT_DATA" >>"$EVENTS_FILE"
  ) 200>"$LOCK_FILE"
fi
