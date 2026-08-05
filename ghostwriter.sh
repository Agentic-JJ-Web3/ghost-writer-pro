#!/usr/bin/env bash

###############################################################################
# GhostWriter Pro - Human Writing Simulation
#
# Writes markdown with realistic human behaviors:
#   - Character-by-character typing
#   - Typos and corrections
#   - Paragraph rewrites
#   - Session-based work patterns (morning/lunch/afternoon/evening)
#   - Overnight gaps
#   - Context-aware commit messages
#
# Usage:
# ./ghostwriter-pro.sh \
#     --input article.md \
#     --output blog.md \
#     --start "2026-07-15 08:30" \
#     --end   "2026-07-17 17:45" \
#     --typing-speed 50 \
#     --typo-rate 0.03 \
#     --session "coding" \
#     --verbose
###############################################################################

set -e

##############################
# Defaults & Configurations
##############################

TYPING_SPEED=50     # Characters per second (avarage)
TYPO_RATE=0.03      # Probability of typo per character
TYPO_FIX_DELAY=2      # Seconds before fixing a typo
REWRITE_PROB=0.15     # Probability of paragraph rewrite
SESSION_PATTERN="balanced" # Options: balanced, coding, academic, casual

# Work session definitions (hour ranges)
declare -A SESSIONS=(
    ["morning"]="06:00-12:00"
    ["lunch"]="12:00-13:30"
    ["afternoon"]="13:30-18:00"
    ["evening"]="18:00-23:00"
    ["night"]="23:00-06:00"
)

# Context-aware message templates by topic
declare -A CONTEXT_MSGS=(
    ["introduction"]="Introduce concept|Set context|Open discussion|Frame problem"
    ["explanation"]="Explain mechanism|Clarify process|Describe behavior|Detail implementation"
    ["example"]="Add example|Show usage|Demonstrate with code|Provide illustration"
    ["code"]="Write cdoe block|Add function|Implement logic|Define structure"
    ["bash"]="ExplainBash syntaxt|Add shell command|Describe pipeline|show script"
      ["linux"]="Describe Linux feature|Explain kernel concept|Add system call|Detail filesystem"
    ["docker"]="Add Dockerfile|Explain container|Show docker command|Describe image build"
    ["networking"]="Explain protocol|Add network config|Describe routing|Show connectivity"
    ["security"]="Discuss security|Add auth method|Explain encryption|Detail permissions"
    ["conclusion"]="Summarize key points|Conclude argument|Wrap discussion|Final thoughts"
    ["editing"]="Refine paragraph|Improve wording|Enhance clarity|Polish content"
)

##############################
# Parse arguments
##############################

while [[ $# -gt 0 ]]; do
    case "$1" in
        --input) INPUT="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --start) START="$2"; shift 2 ;;
        --end) END="$2"; shift 2 ;;
        --typing-speed) TYPING_SPEED="$2"; shift 2 ;;
        --typo-rate) TYPO_RATE="$2"; shift 2 ;;
        --session) SESSION_PATTERN="$2"; shift 2 ;;
        --verbose) VERBOSE=1; shift ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

##############################
# Validation
##############################

[[ -f "$INPUT" ]] || { echo "Input file not found."; exit 1; }
touch "$OUTPUT"
> "$OUTPUT"
git rev-parse --is-inside-work-tree >/dev/null

##############################
# Time utilities
##############################
START_EPOCH=$(date -d "$START" +%s)
END_EPOCH=$(date -d "$END" +%s)
TOTAL_SECONDS=$((END_EPOCH - START_EPOCH))

# Parse session times
get_session_start() {
    local session=$1
    local time_range=${SESSIONS[$session]}
    echo $(date -d "${time_range%-*}" +%s 2>/dev/null || echo 0)
}

get_session_end() {
    local session=$1
    local time_range=${SESSIONS[$session]}
    echo $(date -d "${time_range#*-}" +%s 2>/dev/null || echo 0)
}

# Check if time is in work session 
is_working_hours() {
    local timestamp=$1
    local hour=$(date -d "@$timestamp" +%H)
    local min=$(date -d "@$timestamp" +%M)
    local time_num=$((10#$hour * 100 + 10#$min))
    
    case "$SESSION_PATTERN" in
        "coding")
            [[ $time_num -ge 900 && $time_num -lt 1200 ]] || \
            [[ $time_num -ge 1330 && $time_num -lt 1800 ]] || \
            [[ $time_num -ge 2000 && $time_num -lt 2300 ]]
            ;;
        "academic")
            [[ $time_num -ge 800 && $time_num -lt 1200 ]] || \
            [[ $time_num -ge 1400 && $time_num -lt 1700 ]] || \
            [[ $time_num -ge 1900 && $time_num -lt 2200 ]]
            ;;
        "casual")
            [[ $time_num -ge 1000 && $time_num -lt 1400 ]] || \
            [[ $time_num -ge 1500 && $time_num -lt 1900 ]] || \
            [[ $time_num -ge 2100 && $time_num -lt 0100 ]]
            ;;
        *)  # balanced
            [[ $time_num -ge 800 && $time_num -lt 1200 ]] || \
            [[ $time_num -ge 1300 && $time_num -lt 1700 ]] || \
            [[ $time_num -ge 1900 && $time_num -lt 2200 ]]
            ;;
    esac
}

# Calculate next working time
next_working_time() {
    local current=$1
    local attempts=0
    while ! is_working_hours $current && [[ $attempts -lt 100 ]]; do
        current=$((current + 300))  # Jump 5 minutes
        attempts=$((attempts + 1))
    done
    echo $current
}

##############################
# Context detection
##############################

detect_context() {
    local line="$1"
    local line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')
    
    # Check for keywords
    if echo "$line_lower" | grep -q -E "^(# |## |# )?introduction|overview|background"; then
        echo "introduction"
    elif echo "$line_lower" | grep -q -E "example|sample|instance|illustrate"; then
        echo "example"
    elif echo "$line_lower" | grep -q -E "code|function|def |class |import|return|console\.log|print|var |let |const"; then
        echo "code"
    elif echo "$line_lower" | grep -q -E "bash|shell|terminal|command|echo|grep|awk|sed"; then
        echo "bash"
    elif echo "$line_lower" | grep -q -E "linux|kernel|system|process|memory|file system|permission"; then
        echo "linux"
    elif echo "$line_lower" | grep -q -E "docker|container|image|build|push|pull|registry"; then
        echo "docker"
    elif echo "$line_lower" | grep -q -E "network|tcp|ip|dns|http|ssl|port|firewall"; then
        echo "networking"
    elif echo "$line_lower" | grep -q -E "security|auth|encrypt|decrypt|key|certificate|password"; then
        echo "security"
    elif echo "$line_lower" | grep -q -E "^(# |## )?conclusion|summary|final|wrap up"; then
        echo "conclusion"
    else
        echo "explanation"
    fi
}
