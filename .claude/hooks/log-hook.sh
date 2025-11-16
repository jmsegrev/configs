#!/bin/bash

# Generic hook that logs all hook payloads with enhanced details

# Log file
LOGFILE="/tmp/claude-hooks.log"

# Read the input
INPUT=$(cat)

# Extract hook event name and tool info
HOOK_NAME=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"' 2>/dev/null)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)

# Extract tool-specific details
DETAILS=""
if [ "$TOOL_NAME" = "Bash" ]; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
    DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // ""' 2>/dev/null)
    if [ -n "$COMMAND" ] && [ "$COMMAND" != "null" ]; then
        DETAILS=" | Command: $COMMAND"
    fi
    if [ -n "$DESCRIPTION" ] && [ "$DESCRIPTION" != "null" ]; then
        DETAILS="$DETAILS | Desc: $DESCRIPTION"
    fi
elif [ "$TOOL_NAME" = "Read" ]; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
    if [ -n "$FILE_PATH" ] && [ "$FILE_PATH" != "null" ]; then
        DETAILS=" | File: $FILE_PATH"
    fi
fi

# Log the summary line
echo "=== $HOOK_NAME Hook $(date)${DETAILS} ===" >> "$LOGFILE"
echo "$INPUT" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# Pretty print if it's JSON
echo "=== Pretty Printed ===" >> "$LOGFILE"
echo "$INPUT" | jq '.' >> "$LOGFILE" 2>&1
echo "---" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# Pass through the input unchanged
echo "$INPUT"
