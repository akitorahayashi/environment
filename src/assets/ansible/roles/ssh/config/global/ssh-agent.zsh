# Automatic startup and reuse of SSH Agent
SSH_AGENT_PID_FILE="$HOME/.ssh/ssh-agent.pid"
SSH_AUTH_SOCK_FILE="$HOME/.ssh/ssh-agent.sock"

# Check existing SSH agent process
if [ -f "$SSH_AGENT_PID_FILE" ]; then
    SSH_AGENT_PID=$(cat "$SSH_AGENT_PID_FILE")
    if kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        # If the process is alive, set environment variables
        export SSH_AGENT_PID
        export SSH_AUTH_SOCK=$(cat "$SSH_AUTH_SOCK_FILE")
    else
        # If the process is dead, remove files
        rm -f "$SSH_AGENT_PID_FILE" "$SSH_AUTH_SOCK_FILE"
    fi
fi

# If SSH agent is not running, start a new one
if [ -z "$SSH_AGENT_PID" ] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
    eval "$(ssh-agent -s)"
    echo "$SSH_AGENT_PID" > "$SSH_AGENT_PID_FILE"
    echo "$SSH_AUTH_SOCK" > "$SSH_AUTH_SOCK_FILE"
fi
