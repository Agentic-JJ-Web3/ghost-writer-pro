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
get_commit_message() {
    local context="$1"
    local messages="${CONTEXT_MSGS[$context]:-${CONTEXT_MSGS[explanation]}}"
    IFS='|' read -ra msgs <<< "$messages"
    echo "${msgs[$RANDOM % ${#msgs[@]}]}"
}

##############################
# Writing simulation functions
##############################
# Type a word character by character
type_word() {
    local word="$1"
    local current_time="$2"
    local full_word=""
    local typed=""
    
    # Determine if we'll make a typo
    local make_typo=$(awk -v rate="$TYPO_RATE" 'BEGIN { print (rand() < rate) ? 1 : 0 }')
    local typo_word=""
    local typo_pos=0
    
    if [[ $make_typo -eq 1 && ${#word} -gt 3 ]]; then
        # Create a typo (swap adjacent letters or substitute)
        typo_pos=$((RANDOM % (${#word} - 1)))
        typo_word="$word"
        local char1="${word:$typo_pos:1}"
        local char2="${word:$typo_pos+1:1}"
        # Swap or substitute
        if [[ $((RANDOM % 2)) -eq 0 ]]; then
            # Swap adjacent
            typo_word="${word:0:$typo_pos}${char2}${char1}${word:$typo_pos+2}"
        else
            # Substitute with random letter
            local new_char=$(printf "\\$(printf '%03o' $((97 + RANDOM % 26)))")
            typo_word="${word:0:$typo_pos}${new_char}${word:$typo_pos+1}"
        fi
    fi
    
    # Type the word character by character
    for ((i=0; i<${#word}; i++)); do
        local char="${word:$i:1}"
        
        # If we're at typo position, type the wrong character
        if [[ $make_typo -eq 1 && $i -eq $typo_pos ]]; then
            typed+="${typo_word:$i:1}"
            full_word+="${typo_word:$i:1}"
        else
            typed+="$char"
            full_word+="$char"
        fi
        
        # Show progress if verbose
        if [[ -n "$VERBOSE" ]]; then
            printf "\r%s" "$full_word"
        fi
        
        # Typing delay (simulate real typing speed)
        local char_delay=$(awk -v speed="$TYPING_SPEED" 'BEGIN { printf "%.2f", 1/speed }')
        sleep "$char_delay"
    done
    
    # If we made a typo, fix it
    if [[ $make_typo -eq 1 && ${#word} -gt 3 ]]; then
        if [[ -n "$VERBOSE" ]]; then
            echo -e "\n  [typo] fixing..."
        fi
        
        sleep "$TYPO_FIX_DELAY"
        
        # Backspace and retype correct word
        for ((i=0; i<${#word}; i++)); do
            typed="${typed%?}"
            if [[ -n "$VERBOSE" ]]; then
                printf "\r%s" "$typed"
            fi
            sleep 0.05
        done
        
        # Retype correctly
        for ((i=0; i<${#word}; i++)); do
            char="${word:$i:1}"
            typed+="$char"
            if [[ -n "$VERBOSE" ]]; then
                printf "\r%s" "$typed"
            fi
            sleep 0.06
        done
        
        # Commit the correction
        local fix_time=$((current_time + TYPO_FIX_DELAY))
        local fix_date=$(date -d "@$fix_time" "+%Y-%m-%d %H:%M:%S")
        echo -n "$word " >> "$OUTPUT"
        git add "$OUTPUT"
        GIT_AUTHOR_DATE="$fix_date" GIT_COMMITTER_DATE="$fix_date" \
            git commit -m "Fix typo" >/dev/null 2>&1
        [[ -n "$VERBOSE" ]] && echo -e "\n  [fixed: $word]"
    fi
    
    echo -n "$word " >> "$OUTPUT"
    echo "$typed"
}

# Simulate paragraph rewrite
rewrite_paragraph() {
    local current_time="$1"
    
    # Get last paragraph from output
    local last_para=$(tac "$OUTPUT" 2>/dev/null | grep -v "^$" | head -1 || echo "")
    if [[ -z "$last_para" ]]; then
        return
    fi
    
    [[ -n "$VERBOSE" ]] && echo -e "\n✍️  Rewriting paragraph..."
    
    # Simulate thinking
    local think_time=$((RANDOM % 30 + 10))
    sleep "$think_time"
    current_time=$((current_time + think_time))
    
    # Backspace through the paragraph
    local word_count=$(echo "$last_para" | wc -w)
    for ((i=0; i<word_count; i++)); do
        echo -n "" >> "$OUTPUT"  # Remove last word
        sleep 0.2
    done

   # Remove the paragraph
    sed -i '' -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "$OUTPUT" 2>/dev/null || true
    
    # Retype it differently (simplified - just append as new)
    echo "" >> "$OUTPUT"
    echo " [rewritten] " >> "$OUTPUT"
    
    # Commit the rewrite
    local rewrite_date=$(date -d "@$current_time" "+%Y-%m-%d %H:%M:%S")
    git add "$OUTPUT"
    GIT_AUTHOR_DATE="$rewrite_date" GIT_COMMITTER_DATE="$rewrite_date" \
        git commit -m "Refine paragraph" >/dev/null 2>&1
}

##############################
# Main writing loop
##############################

echo "👻 GhostWriter Pro Starting..."
echo "Input: $INPUT"
echo "Output: $OUTPUT"
echo "Time window: $START → $END"
echo "Session pattern: $SESSION_PATTERN"
echo "Typing speed: $TYPING_SPEED chars/sec"
echo "Typo rate: $TYPO_RATE"
echo "---"

WORD_COUNT=$(wc -w < "$INPUT")
TOTAL_AVAILABLE=$TOTAL_SECONDS
STEP=$((TOTAL_AVAILABLE / WORD_COUNT))

current_time=$START_EPOCH
word_index=0

# Ensure we start during working hours
current_time=$(next_working_time $current_time)

# Read file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
        echo "" >> "$OUTPUT"
        git add "$OUTPUT"
        local empty_date=$(date -d "@$current_time" "+%Y-%m-%d %H:%M:%S")
        GIT_AUTHOR_DATE="$empty_date" GIT_COMMITTER_DATE="$empty_date" \
            git commit -m "Add spacing" >/dev/null 2>&1
        continue
    fi
    
    # Detect context for this line
    context=$(detect_context "$line")
    
    for word in $line; do
        word_index=$((word_index + 1))
        
        # Ensure we're in working hours
        if ! is_working_hours $current_time; then
            local next_time=$(next_working_time $current_time)
            local gap=$((next_time - current_time))
            
            # Sleep overnight or long break
            local gap_hours=$((gap / 3600))
            echo "🌙 Overnight gap: ${gap_hours}h (sleeping...)"
            
            # Add a "morning start" commit
            local gap_date=$(date -d "@$next_time" "+%Y-%m-%d %H:%M:%S")
            GIT_AUTHOR_DATE="$gap_date" GIT_COMMITTER_DATE="$gap_date" \
                git commit --allow-empty -m "Start new session" >/dev/null 2>&1
            
            current_time=$next_time
            
            # Simulate morning routine
            echo "☕ Morning coffee..."
            sleep 2
        fi
        
        # Current date for this word
        word_date=$(date -d "@$current_time" "+%Y-%m-%d %H:%M:%S")
        
        # Show context if verbose
        [[ -n "$VERBOSE" ]] && echo -e "\n[${word_date}] Context: $context"
        
        # Type the word
        type_word "$word" "$current_time"
        
        # Commit with context-aware message
        local msg=$(get_commit_message "$context")
        git add "$OUTPUT"
        GIT_AUTHOR_DATE="$word_date" GIT_COMMITTER_DATE="$word_date" \
            git commit -m "$msg" >/dev/null 2>&1
        
        # Show progress
        echo "✓ [$word_index/$WORD_COUNT] '$word' → $msg"
        
        # Advance time with jitter
        local jitter=$((RANDOM % 20 - 10))
        current_time=$((current_time + STEP + jitter))
        
        # Random short break
        if (( RANDOM % 25 == 0 )); then
            local break=$((RANDOM % 120 + 30))
            echo "  ☕ Short break (${break}s)"
            sleep $((break / 10))  # Compressed for demo
            current_time=$((current_time + break))
        fi
        
        # Paragraph rewrite chance
        if (( RANDOM % 100 < $(awk "BEGIN {print $REWRITE_PROB * 100}") )); then
            rewrite_paragraph "$current_time"
        fi
        
        # Session change detection
        local hour=$(date -d "@$current_time" +%H)
        if [[ $hour -eq 12 && $((RANDOM % 3)) -eq 0 ]]; then
            echo "  🍽️ Lunch break"
            current_time=$((current_time + 3600))  # 1 hour lunch
        fi
        
        if [[ $hour -eq 17 && $((RANDOM % 2)) -eq 0 ]]; then
            echo "  🏠 End of day"
            current_time=$((current_time + 7200))  # Evening break
        fi
    done
    
    echo "" >> "$OUTPUT"  # Newline after line
    
done < "$INPUT"

echo ""
echo "✅ Writing complete!"
echo "📝 Output: $OUTPUT"
echo "📊 Commits: $(git rev-list --count HEAD)"
echo "🕐 Last commit: $(git log -1 --format=%ai)"
echo ""
echo "💡 To see the history: git log --oneline --graph"