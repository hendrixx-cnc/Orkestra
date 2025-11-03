#!/bin/bash
# Example: How to save voting records to the correct project location

# Load current project path
ORKESTRA_ROOT="${ORKESTRA_ROOT:-$(pwd)}"
CURRENT_PROJECT_FILE="$ORKESTRA_ROOT/CONFIG/current-project.json"

# Get current project directory
if [ -f "$CURRENT_PROJECT_FILE" ]; then
    PROJECT_DIR=$(jq -r '.path' "$CURRENT_PROJECT_FILE")
else
    echo "Error: No current project set"
    exit 1
fi

# Define log directories (IN THE PROJECT, not in Orkestra)
VOTING_DIR="$PROJECT_DIR/logs/voting"
OUTCOMES_DIR="$PROJECT_DIR/logs/outcomes"
EXECUTION_DIR="$PROJECT_DIR/logs/execution"

# Ensure directories exist
mkdir -p "$VOTING_DIR" "$OUTCOMES_DIR" "$EXECUTION_DIR"

# Example: Save a vote
save_vote() {
    local vote_id=$1
    local proposal=$2
    local vote_data=$3
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    local vote_file="$VOTING_DIR/vote-${vote_id}.json"
    
    cat > "$vote_file" << EOF
{
  "id": "$vote_id",
  "timestamp": "$timestamp",
  "project": "$(basename $PROJECT_DIR)",
  "proposal": $proposal,
  "voters": $vote_data,
  "result": "approved"
}
EOF
    
    echo "Vote saved to: $vote_file"
}

# Example: Save an outcome
save_outcome() {
    local outcome_id=$1
    local vote_id=$2
    local decision=$3
    local plan=$4
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    local outcome_file="$OUTCOMES_DIR/outcome-${outcome_id}.json"
    
    cat > "$outcome_file" << EOF
{
  "id": "$outcome_id",
  "timestamp": "$timestamp",
  "project": "$(basename $PROJECT_DIR)",
  "vote_id": "$vote_id",
  "decision": $decision,
  "implementation_plan": $plan
}
EOF
    
    echo "Outcome saved to: $outcome_file"
}

# Example: Log execution
log_execution() {
    local message=$1
    local agent=$2
    
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_file="$EXECUTION_DIR/$(date +%Y-%m-%d).log"
    
    echo "[$timestamp] $agent: $message" >> "$log_file"
}

# Example usage:
# save_vote "vote-001" '{"title":"Add feature X"}' '{"claude":{"vote":"approve"}}'
# save_outcome "outcome-001" "vote-001" '{"title":"Approved"}' '{"tasks":[]}'
# log_execution "Created new file" "CLAUDE"

echo "✓ Voting logs go to: $VOTING_DIR"
echo "✓ Outcome logs go to: $OUTCOMES_DIR"
echo "✓ Execution logs go to: $EXECUTION_DIR"
echo ""
echo "Key points:"
echo "  - All logs stay WITH the project"
echo "  - Orkestra framework stays clean"
echo "  - Each project has complete history"
