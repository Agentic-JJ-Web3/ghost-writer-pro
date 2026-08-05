#!/usr/bin/env bash

###############################################################################
# GhostWriter Pro - Human Writing Simulation
#
# A sophisticated markdown writing simulator with realistic human behaviors,
# resume support, progress tracking, and comprehensive logging.
#
# Usage:
#   ./ghostwriter.sh config.yml
#   ./ghostwriter.sh --resume
#   ./ghostwriter.sh --config config.yml --resume
###############################################################################

set -e
set -o pipefail

##############################
# Global Configuration
##############################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROGRESS_FILE="${SCRIPT_DIR}/.ghostwriter-progress"
LOG_FILE="${SCRIPT_DIR}/ghostwriter.log"
DEFAULT_CONFIG="${SCRIPT_DIR}/ghostwriter.yml"

# Default values (overridden by config)
INPUT=""
OUTPUT=""
START=""
END=""
MIN_DELAY=2
MAX_DELAY=8
TYPING_SPEED=50
TYPO_RATE=0.03
REWRITE_PROB=0.15
SESSION_PATTERN="balanced"
VERBOSE=0
RESUME=0
CONFIG_FILE=""

# Runtime state
WORD_COUNT=0
CURRENT_WORD_INDEX=0
CURRENT_TIME=0
START_EPOCH=0
END_EPOCH=0
TOTAL_SECONDS=0
STEP=0
COMMIT_COUNT=0
INTERRUPTED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

##############################
# Logging Functions
##############################

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Console output with colors
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") [[ $VERBOSE -eq 1 ]] && echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        "PROGRESS") echo -e "${CYAN}[PROGRESS]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
        "ACTION") echo -e "${PURPLE}[ACTION]${NC} $message" ;;
        *) echo "$message" ;;
    esac
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

log_info() { log "INFO" "$1"; }
log_warn() { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }
log_debug() { log "DEBUG" "$1"; }
log_progress() { log "PROGRESS" "$1"; }
log_success() { log "SUCCESS" "$1"; }
log_action() { log "ACTION" "$1"; }

##############################
# Progress Bar Functions
##############################

show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percent=$((current * 100 / total))
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    # Create progress bar
    local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=0; i<empty; i++)); do bar="${bar}░"; done
    
    # Calculate ETA
    local eta=""
    if [[ $current -gt 0 && $CURRENT_TIME -gt 0 ]]; then
        local elapsed=$((CURRENT_TIME - START_EPOCH))
        local avg_time=$((elapsed / current))
        local remaining=$(( (total - current) * avg_time ))
        local hours=$((remaining / 3600))
        local mins=$(( (remaining % 3600) / 60 ))
        eta="${hours}h ${mins}m remaining"
    else
        eta="calculating..."
    fi
    
    printf "\r${CYAN}%s${NC} %3d%% ${GREEN}${bar}${NC} ${YELLOW}%d/%d${NC} words %s" \
        "Writing:" "$percent" "$current" "$total" "$eta"
}

##############################
# Parser Functions
##############################

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --config|-c)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --resume|-r)
                RESUME=1
                shift
                ;;
            --verbose|-v)
                VERBOSE=1
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Default config path
    [[ -z "$CONFIG_FILE" ]] && CONFIG_FILE="$DEFAULT_CONFIG"
}

show_help() {
    cat << EOF
GhostWriter Pro - Human Writing Simulation

Usage:
    $0 [options]

Options:
    --config, -c FILE    Configuration file (default: ghostwriter.yml)
    --resume, -r         Resume from last saved progress
    --verbose, -v        Verbose output
    --help, -h           Show this help

Configuration file (YAML):
    input: article.md
    output: blog.md
    start: "2026-07-15 08:30"
    end: "2026-07-15 17:45"
    min_delay: 2
    max_delay: 8
    typing_speed: 50      # Characters per second
    typo_rate: 0.03       # Probability of typo per character
    rewrite_prob: 0.15    # Probability of paragraph rewrite
    session_pattern: balanced  # balanced | coding | academic | casual

Example:
    $0 --config my_config.yml
    $0 --resume
EOF
}

##############################
# Configuration Parser (YAML)
##############################

parse_yaml() {
    local file="$1"
    local prefix="$2"
    local s='[[:space:]]*'
    local w='[a-zA-Z0-9_]*'
    local fs=$(echo @ | tr @ '\034')
    
    sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$file" |
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=\"%s\"\n", "'$prefix'", vn, $2, $3);
        }
    }'
}

load_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        exit 1
    fi
    
    log_info "Loading configuration from: $config_file"
    
    # Parse YAML and set variables
    eval $(parse_yaml "$config_file")
    
    # Map config variables to script variables
    INPUT="${input:-$INPUT}"
    OUTPUT="${output:-$OUTPUT}"
    START="${start:-$START}"
    END="${end:-$END}"
    MIN_DELAY="${min_delay:-$MIN_DELAY}"
    MAX_DELAY="${max_delay:-$MAX_DELAY}"
    TYPING_SPEED="${typing_speed:-$TYPING_SPEED}"
    TYPO_RATE="${typo_rate:-$TYPO_RATE}"
    REWRITE_PROB="${rewrite_prob:-$REWRITE_PROB}"
    SESSION_PATTERN="${session_pattern:-$SESSION_PATTERN}"
    
    # Validate required fields
    [[ -z "$INPUT" ]] && { log_error "Missing required config: input"; exit 1; }
    [[ -z "$OUTPUT" ]] && { log_error "Missing required config: output"; exit 1; }
    [[ -z "$START" ]] && { log_error "Missing required config: start"; exit 1; }
    [[ -z "$END" ]] && { log_error "Missing required config: end"; exit 1; }
    
    log_debug "Configuration loaded:"
    log_debug "  INPUT: $INPUT"
    log_debug "  OUTPUT: $OUTPUT"
    log_debug "  START: $START"
    log_debug "  END: $END"
    log_debug "  MIN_DELAY: $MIN_DELAY"
    log_debug "  MAX_DELAY: $MAX_DELAY"
}

##############################
# Validation Functions
##############################

validate_input() {
    if [[ ! -f "$INPUT" ]]; then
        log_error "Input file not found: $INPUT"
        exit 1
    fi
    
    # Validate git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        log_error "Not inside a git repository"
        log_error "Please run this script from within a git repo"
        exit 1
    fi
    
    # Validate dates
    if ! date -d "$START" >/dev/null 2>&1; then
        log_error "Invalid start date: $START"
        exit 1
    fi
    
    if ! date -d "$END" >/dev/null 2>&1; then
        log_error "Invalid end date: $END"
        exit 1
    fi
    
    START_EPOCH=$(date -d "$START" +%s)
    END_EPOCH=$(date -d "$END" +%s)
    
    if [[ $START_EPOCH -ge $END_EPOCH ]]; then
        log_error "Start time must be before end time"
        exit 1
    fi
    
    log_debug "Validation passed"
    log_debug "  Start epoch: $START_EPOCH"
    log_debug "  End epoch: $END_EPOCH"
}

##############################
# Timeline Calculation
##############################

calculate_timeline() {
    WORD_COUNT=$(wc -w < "$INPUT" | tr -d ' ')
    TOTAL_SECONDS=$((END_EPOCH - START_EPOCH))
    STEP=$((TOTAL_SECONDS / WORD_COUNT))
    
    log_info "Word count: $WORD_COUNT"
    log_info "Total timeline: $TOTAL_SECONDS seconds ($((TOTAL_SECONDS / 3600)) hours)"
    log_info "Average spacing: $STEP seconds"
}

##############################
# Session Detection
##############################

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

next_working_time() {
    local current=$1
    local attempts=0
    while ! is_working_hours $current && [[ $attempts -lt 100 ]]; do
        current=$((current + 300))
        attempts=$((attempts + 1))
    done
    echo $current
}

##############################
# Context Detection
##############################

detect_context() {
    local line="$1"
    local line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')
    
    if echo "$line_lower" | grep -q -E "^(# |## )?introduction|overview|background"; then
        echo "introduction"
    elif echo "$line_lower" | grep -q -E "example|sample|instance|illustrate"; then
        echo "example"
    elif echo "$line_lower" | grep -q -E "code|function|def |class |import|return|console\.log|print|var |let |const|function"; then
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
    
    # Context-aware message templates
    declare -A CONTEXT_MSGS=(
        ["introduction"]="Introduce concept|Set context|Open discussion|Frame problem"
        ["explanation"]="Explain mechanism|Clarify process|Describe behavior|Detail implementation"
        ["example"]="Add example|Show usage|Demonstrate with code|Provide illustration"
        ["code"]="Write code block|Add function|Implement logic|Define structure"
        ["bash"]="Explain Bash syntax|Add shell command|Describe pipeline|Show scripting"
        ["linux"]="Describe Linux feature|Explain kernel concept|Add system call|Detail filesystem"
        ["docker"]="Add Dockerfile|Explain container|Show docker command|Describe image build"
        ["networking"]="Explain protocol|Add network config|Describe routing|Show connectivity"
        ["security"]="Discuss security|Add auth method|Explain encryption|Detail permissions"
        ["conclusion"]="Summarize key points|Conclude argument|Wrap discussion|Final thoughts"
        ["editing"]="Refine paragraph|Improve wording|Enhance clarity|Polish content"
    )
    
    local messages="${CONTEXT_MSGS[$context]:-${CONTEXT_MSGS[explanation]}}"
    IFS='|' read -ra msgs <<< "$messages"
    echo "${msgs[$RANDOM % ${#msgs[@]}]}"
}

##############################
# Markdown Handling
##############################

process_markdown_element() {
    local element="$1"
    local content="$2"
    local current_time="$3"
    
    case "$element" in
        "heading")
            echo "$content" >> "$OUTPUT"
            local msg="Add heading: $(echo "$content" | sed 's/^#* //')"
            commit_change "$current_time" "$msg"
            ;;
        "code_block")
            echo "$content" >> "$OUTPUT"
            commit_change "$current_time" "Add code block"
            ;;
        "list_item")
            echo "$content" >> "$OUTPUT"
            commit_change "$current_time" "Add list item"
            ;;
        "blockquote")
            echo "$content" >> "$OUTPUT"
            commit_change "$current_time" "Add quote"
            ;;
        "table")
            echo "$content" >> "$OUTPUT"
            commit_change "$current_time" "Add table"
            ;;
        "blank_line")
            echo "" >> "$OUTPUT"
            commit_change "$current_time" "Add spacing"
            ;;
        "text")
            process_words "$content" "$current_time"
            ;;
    esac
}

process_words() {
    local line="$1"
    local current_time="$2"
    
    # Handle word-by-word typing
    for word in $line; do
        write_word "$word" "$current_time"
        current_time=$((current_time + STEP + (RANDOM % 20 - 10)))
        COMMIT_COUNT=$((COMMIT_COUNT + 1))
        show_progress "$CURRENT_WORD_INDEX" "$WORD_COUNT"
        save_progress
    done
}

##############################
# Core Writing Functions
##############################

write_word() {
    local word="$1"
    local current_time="$2"
    local typed=""
    
    CURRENT_WORD_INDEX=$((CURRENT_WORD_INDEX + 1))
    
    # Determine if we'll make a typo
    local make_typo=0
    if awk -v rate="$TYPO_RATE" 'BEGIN { srand(); exit !(rand() < rate) }'; then
        make_typo=1
    fi
    
    local typo_word="$word"
    local typo_pos=0
    
    if [[ $make_typo -eq 1 && ${#word} -gt 3 ]]; then
        typo_pos=$((RANDOM % (${#word} - 1)))
        typo_word="$word"
        local char1="${word:$typo_pos:1}"
        local char2="${word:$typo_pos+1:1}"
        
        if [[ $((RANDOM % 2)) -eq 0 ]]; then
            typo_word="${word:0:$typo_pos}${char2}${char1}${word:$typo_pos+2}"
        else
            local new_char=$(printf "\\$(printf '%03o' $((97 + RANDOM % 26)))")
            typo_word="${word:0:$typo_pos}${new_char}${word:$typo_pos+1}"
        fi
    fi
    
    # Type character by character
    for ((i=0; i<${#word}; i++)); do
        local char="${word:$i:1}"
        
        if [[ $make_typo -eq 1 && $i -eq $typo_pos ]]; then
            typed+="${typo_word:$i:1}"
        else
            typed+="$char"
        fi
        
        if [[ $VERBOSE -eq 1 ]]; then
            printf "\r%s" "$typed"
        fi
        
        local char_delay=$(awk -v speed="$TYPING_SPEED" 'BEGIN { printf "%.2f", 1/speed }')
        sleep "$char_delay"
    done
    
    # Fix typo if made
    if [[ $make_typo -eq 1 && ${#word} -gt 3 ]]; then
        if [[ $VERBOSE -eq 1 ]]; then
            echo -e "\n  [typo] fixing..."
        fi
        
        sleep "$MIN_DELAY"
        
        # Backspace and retype
        for ((i=0; i<${#word}; i++)); do
            typed="${typed%?}"
            if [[ $VERBOSE -eq 1 ]]; then
                printf "\r%s" "$typed"
            fi
            sleep 0.05
        done
        
        typed=""
        for ((i=0; i<${#word}; i++)); do
            char="${word:$i:1}"
            typed+="$char"
            if [[ $VERBOSE -eq 1 ]]; then
                printf "\r%s" "$typed"
            fi
            sleep 0.06
        done
        
        # Commit the correction
        local fix_time=$((current_time + MIN_DELAY))
        commit_change "$fix_time" "Fix typo"
    fi
    
    # Write word to output
    echo -n "$word " >> "$OUTPUT"
    
    # Commit with context-aware message
    local context=$(detect_context "$word")
    local msg=$(get_commit_message "$context")
    commit_change "$current_time" "$msg"
}

commit_change() {
    local timestamp="$1"
    local message="$2"
    local date_str=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S")
    
    git add "$OUTPUT" >/dev/null 2>&1
    
    GIT_AUTHOR_DATE="$date_str" \
    GIT_COMMITTER_DATE="$date_str" \
    git commit -m "$message" >/dev/null 2>&1 || true
    
    log_debug "Commit: $date_str - $message"
}

generate_timestamp() {
    local current_time=$1
    local jitter=$((RANDOM % 20 - 10))
    echo $((current_time + jitter))
}

random_pause() {
    local min=$1
    local max=$2
    local delay=$((RANDOM % (max - min + 1) + min))
    sleep "$delay"
    echo $delay
}

##############################
# Progress Management
##############################

save_progress() {
    cat > "$PROGRESS_FILE" << EOF
CURRENT_WORD_INDEX=$CURRENT_WORD_INDEX
COMMIT_COUNT=$COMMIT_COUNT
CURRENT_TIME=$CURRENT_TIME
EOF
}

load_progress() {
    if [[ -f "$PROGRESS_FILE" ]]; then
        source "$PROGRESS_FILE"
        log_info "Resuming from word $CURRENT_WORD_INDEX (already $COMMIT_COUNT commits)"
        return 0
    else
        return 1
    fi
}

cleanup_progress() {
    rm -f "$PROGRESS_FILE"
}

##############################
# Interrupt Handling
##############################

interrupt_handler() {
    log_warn "\n\nStopping... (Ctrl+C detected)"
    INTERRUPTED=1
    
    # Save progress
    save_progress
    log_info "Progress saved to: $PROGRESS_FILE"
    log_info "Resume with: $0 --resume"
    
    # Show stats
    show_statistics
    
    exit 130
}

##############################
# Statistics
##############################

show_statistics() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}📊 Statistics${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Words Written: $CURRENT_WORD_INDEX"
    echo "Commits Created: $COMMIT_COUNT"
    
    if [[ $CURRENT_WORD_INDEX -gt 0 ]]; then
        local elapsed=$((CURRENT_TIME - START_EPOCH))
        local hours=$((elapsed / 3600))
        local mins=$(( (elapsed % 3600) / 60 ))
        echo "Elapsed Timeline: ${hours}h ${mins}m"
        
        local avg_interval=$((elapsed / CURRENT_WORD_INDEX))
        echo "Average Commit Interval: ${avg_interval} seconds"
    fi
    
    echo "Output: $OUTPUT"
    echo "Log: $LOG_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

##############################
# Main Writing Loop
##############################

write_article() {
    local start_word=1
    
    # Resume support
    if [[ $RESUME -eq 1 ]] && load_progress; then
        start_word=$((CURRENT_WORD_INDEX + 1))
        log_info "Resuming from word $start_word"
    else
        # Initialize output file
        > "$OUTPUT"
        log_info "Starting fresh writing session"
    fi
    
    # Ensure we start during working hours
    CURRENT_TIME=$(next_working_time $START_EPOCH)
    
    # Count total words
    local total_words=$(wc -w < "$INPUT" | tr -d ' ')
    local current_word=0
    
    trap interrupt_handler INT TERM
    
    log_info "Starting main writing loop..."
    log_info "Total words: $total_words"
    
    # Read and process file line by line
    local line_num=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        line_num=$((line_num + 1))
        
        # Skip lines before resume point
        if [[ $line_num -lt $start_word ]]; then
            continue
        fi
        
        # Detect and process markdown elements
        if [[ -z "$line" ]]; then
            # Blank line
            process_markdown_element "blank_line" "" "$CURRENT_TIME"
            continue
        elif [[ "$line" =~ ^#{1,6}[[:space:]] ]]; then
            # Heading
            process_markdown_element "heading" "$line" "$CURRENT_TIME"
            continue
        elif [[ "$line" =~ ^[[:space:]]*[-*+][[:space:]] ]]; then
            # List item
            process_markdown_element "list_item" "$line" "$CURRENT_TIME"
            continue
        elif [[ "$line" =~ ^[[:space:]]*[0-9]+\. ]]; then
            # Numbered list
            process_markdown_element "list_item" "$line" "$CURRENT_TIME"
            continue
        elif [[ "$line" =~ ^[[:space:]]*> ]]; then
            # Blockquote
            process_markdown_element "blockquote" "$line" "$CURRENT_TIME"
            continue
        elif [[ "$line" =~ ^[[:space:]]*``` ]]; then
            # Code block
            process_markdown_element "code_block" "$line" "$CURRENT_TIME"
            continue
        elif [[ "$line" =~ ^[[:space:]]*\| ]]; then
            # Table row
            process_markdown_element "table" "$line" "$CURRENT_TIME"
            continue
        else
            # Regular text
            process_markdown_element "text" "$line" "$CURRENT_TIME"
        fi
        
        # Add newline after each line
        echo "" >> "$OUTPUT"
        CURRENT_TIME=$((CURRENT_TIME + 1))
        
        # Random pauses and breaks
        if (( RANDOM % 25 == 0 )); then
            local break_delay=$((RANDOM % 60 + 30))
            log_action "☕ Short break (${break_delay}s)"
            random_pause $MIN_DELAY $break_delay
            CURRENT_TIME=$((CURRENT_TIME + break_delay))
        fi
        
        # Paragraph rewrite chance
        if (( RANDOM % 100 < $(awk "BEGIN {print $REWRITE_PROB * 100}") )); then
            log_action "✍️  Rewriting paragraph..."
            random_pause 5 15
        fi
        
        # Session change detection
        local hour=$(date -d "@$CURRENT_TIME" +%H)
        if [[ $hour -eq 12 && $((RANDOM % 3)) -eq 0 ]]; then
            log_action "🍽️ Lunch break (1 hour)"
            CURRENT_TIME=$((CURRENT_TIME + 3600))
        fi
        
        if [[ $hour -eq 17 && $((RANDOM % 2)) -eq 0 ]]; then
            log_action "🏠 End of day"
            CURRENT_TIME=$((CURRENT_TIME + 7200))
        fi
        
        # Save progress after each line
        save_progress
        
        # Check for interrupt
        if [[ $INTERRUPTED -eq 1 ]]; then
            return
        fi
        
    done < "$INPUT"
    
    # Cleanup on success
    cleanup_progress
    trap - INT TERM
    
    log_success "Writing complete!"
}

##############################
# Main Execution
##############################

main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Load configuration
    load_config "$CONFIG_FILE"
    
    # Validate input
    validate_input
    
    # Calculate timeline
    calculate_timeline
    
    # Start writing
    write_article
    
    # Show statistics
    show_statistics
    
    # Final output
    echo ""
    echo -e "${GREEN}✅ Done!${NC}"
    echo -e "📝 Output: $OUTPUT"
    echo -e "📊 Log: $LOG_FILE"
    echo -e "📈 Commits: $(git rev-list --count HEAD)"
    echo ""
    echo -e "${CYAN}💡 View history:${NC} git log --oneline --graph"
}

##############################
# Script Entry Point
##############################

# Set up trap for interrupt
trap interrupt_handler INT TERM

# Run main function with all arguments
main "$@"