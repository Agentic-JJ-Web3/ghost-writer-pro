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