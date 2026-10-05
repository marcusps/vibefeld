#!/usr/bin/env bash

set -euo pipefail

AGENT_BACKEND="claude"
PROMPT="continue. Take *one* or *two* issues and work on them spawning subagents as necessary. After successfully finishing, close the issue. If not successful, update issues. After this update handoff and land the plane"

usage() {
    cat <<'EOF'
Usage: ./ralph.sh [--codex|--claude|--omp|--copilot]

Defaults to Claude. Pass --codex/--omp/--copilot to run the same prompt via that CLI.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --codex)
            AGENT_BACKEND="codex"
            shift
            ;;
        --claude)
            AGENT_BACKEND="claude"
            shift
            ;;
        --omp)
            AGENT_BACKEND="omp"
            shift
            ;;
        --copilot)
            AGENT_BACKEND="copilot"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

for i in {1..6}; do
    echo "=== Run $i of 6 ==="
    if [[ "$AGENT_BACKEND" == "codex" ]]; then
        codex exec --dangerously-bypass-approvals-and-sandbox --json "$PROMPT" | jq
    elif [[ "$AGENT_BACKEND" == "omp" ]]; then
        timeout 300 omp -p --auto-approve --no-session --no-skills --no-extensions "$PROMPT"
    elif [[ "$AGENT_BACKEND" == "copilot" ]]; then
        timeout 300 copilot -p "$PROMPT" -s --allow-all --no-ask-user
    else
        claude --dangerously-skip-permissions -p "$PROMPT" --verbose --output-format stream-json --include-partial-messages | jq
    fi
    echo ""
done
