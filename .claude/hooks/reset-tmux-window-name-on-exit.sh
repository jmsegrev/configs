#!/bin/bash

# Reset tmux window name to Bash when Claude session ends

# Read the input
INPUT=$(cat)

# Pass through the input unchanged
echo "$INPUT"

# Setup logging
LOG_FILE="/tmp/claude-tmux-hook.log"
LOG_LOCK="/tmp/claude-tmux-hook.lock"

# Helper function for thread-safe logging
log() {
    (
        flock -x 200
        echo "$1" >> "$LOG_FILE"
    ) 200>"$LOG_LOCK"
}

log "========== SessionEnd $(date '+%Y-%m-%d %H:%M:%S') =========="

# Parse session info
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)
log "SessionEnd for session: $SESSION_ID"

# Only proceed if we're in a tmux session
if [ -z "$TMUX" ]; then
    log "Not in tmux, skipping"
    exit 0
fi

# Get current tmux pane and check if this is the active session
TMUX_PANE=$(tmux display-message -p '#{pane_id}' 2>/dev/null)
CURRENT_SESSION_FILE="/tmp/claude-current-session-$TMUX_PANE"
CURRENT_SESSION=$(cat "$CURRENT_SESSION_FILE" 2>/dev/null)

log "Current session for pane $TMUX_PANE: $CURRENT_SESSION"
log "Ending session: $SESSION_ID"

# Only reset if this is the current active session
if [ "$SESSION_ID" = "$CURRENT_SESSION" ]; then
    log "Match! Resetting window name to 'Bash'"
    tmux rename-window "Bash" 2>/dev/null
    log "Window reset complete"
    # Clean up the current session file
    rm -f "$CURRENT_SESSION_FILE"
else
    log "Not current session, skipping reset"
fi
