#!/bin/bash

# Fail closed, not open: a guardrail's job is to block when it can't be sure.
# Without jq we can't parse the command, so we must refuse rather than wave it
# through — otherwise a missing dependency silently disables every block below.
if ! command -v jq >/dev/null 2>&1; then
  echo "BLOCKED: git-guardrails requires 'jq' to inspect the command, but jq is not installed. Install jq (e.g. 'brew install jq') and retry. Refusing to run unguarded." >&2
  exit 2
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

DANGEROUS_PATTERNS=(
  "git push"
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "push --force"
  "reset --hard"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
    exit 2
  fi
done

exit 0
