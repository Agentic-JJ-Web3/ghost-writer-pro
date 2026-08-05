# GhostWriter Pro User Guide

## What is GhostWriter?

GhostWriter is a clever tool that makes it look like you wrote a document over several days, with realistic human writing patterns. It creates a git commit history that looks authentic - complete with typos, corrections, coffee breaks, and natural writing rhythms.

**Think of it as a time machine for your writing process.**

---

## When Would You Use This?

- **Creating realistic git histories** for project portfolios
- **Demonstrating writing process** to clients or employers
- **Testing git visualization tools** with meaningful commit data
- **Building believable project timelines** for demos

---

## Quick Start

### 1. Install Prerequisites

You need:
- **Bash** (comes with macOS/Linux, or use Git Bash on Windows)
- **Git** (installed and configured)
- A git repository (run `git init` if you don't have one)

### 2. Create a Configuration File

Create a file called `ghostwriter.yml` in your project:

```yaml
input: my-draft.md
output: final-blog.md
start: "2026-07-15 08:30"
end: "2026-07-17 17:45"
min_delay: 2
max_delay: 8
typing_speed: 50
typo_rate: 0.03
rewrite_prob: 0.15
session_pattern: balanced
```

### 3. Run GhostWriter

```bash
./ghostwriter.sh
```

**That's it!** Sit back and watch as your document is "written" word by word.

---

## Configuration Explained

Here's what each setting means:

| Setting | What It Does | Example |
|---------|--------------|---------|
| `input` | The file you want to "write" | `my-draft.md` |
| `output` | Where to save the written file | `final-blog.md` |
| `start` | When you began writing | `"2026-07-15 08:30"` |
| `end` | When you finished | `"2026-07-17 17:45"` |
| `min_delay` | Minimum pause between words (seconds) | `2` |
| `max_delay` | Maximum pause between words (seconds) | `8` |
| `typing_speed` | Characters typed per second | `50` |
| `typo_rate` | Chance of making a typo (0-1) | `0.03` (3%) |
| `rewrite_prob` | Chance of revising a paragraph (0-1) | `0.15` (15%) |
| `session_pattern` | Your work schedule | `balanced` |

### Session Patterns

Choose what fits your writing style:

- **`balanced`** - 9am-12pm, 1pm-5pm, 7pm-10pm (typical office hours)
- **`coding`** - 9am-12pm, 1:30pm-6pm, 8pm-11pm (developer schedule)
- **`academic`** - 8am-12pm, 2pm-5pm, 7pm-10pm (student schedule)
- **`casual`** - 10am-2pm, 3pm-7pm, 9pm-1am (night owl schedule)

---

## How It Works

### The Writing Process

1. **Reads your input file** and counts all the words
2. **Spreads writing across your time window** (e.g., 2 days)
3. **Types each word** character by character at your speed
4. **Makes occasional typos** and corrects them (just like a real person!)
5. **Adds pauses** between words and sentences
6. **Creates a git commit** after every word
7. **Backdates each commit** to match the writing timeline

### What Makes It Realistic?

- ✅ **Character-by-character typing** - not instant word dumping
- ✅ **Random typos** - approximately 3% of words have typos
- ✅ **Correction commits** - when a typo is fixed
- ✅ **Coffee breaks** - random 30-90 second pauses
- ✅ **Lunch breaks** - automatic 1-hour pause at noon
- ✅ **End-of-day** - stops writing around 5-6pm
- ✅ **Overnight gaps** - picks up the next morning
- ✅ **Paragraph rewrites** - occasionally revises previous text
- ✅ **Context-aware commits** - messages match what's being written

---

## Using GhostWriter

### Basic Usage

```bash
# Using the default config file (ghostwriter.yml)
./ghostwriter.sh

# Using a specific config file
./ghostwriter.sh --config my-config.yml

# Verbose mode (shows everything)
./ghostwriter.sh --verbose
```

### Resume After Interruption

If you press **Ctrl+C** or the script stops:

```bash
# Continue where you left off
./ghostwriter.sh --resume
```

### Get Help

```bash
./ghostwriter.sh --help
```

---

## What You'll See

### Progress Bar

While running, you'll see:

```
Writing: ██████████░░░░░░░░░░ 42% 512/1231 words 3h 12m remaining
```

This shows:
- How far along you are
- Words written vs. total
- Estimated time remaining

### Example Output

```
[INFO] Loading configuration from: ghostwriter.yml
[INFO] Word count: 1231
[INFO] Total timeline: 83160 seconds (23 hours)
[INFO] Starting main writing loop...
[ACTION] ☕ Short break (45s)
[ACTION] ✍️  Rewriting paragraph...
[PROGRESS] Writing: ██████████░░░░░░ 42% 512/1231 words
[ACTION] 🍽️ Lunch break (1 hour)
[PROGRESS] Writing: ████████████████ 85% 1046/1231 words 45m remaining
[SUCCESS] Writing complete!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Statistics
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Words Written: 1231
Commits Created: 1231
Elapsed Timeline: 23h 15m
Average Commit Interval: 27.1 seconds
Output: blog.md
Log: ghostwriter.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Advanced Tips

### 1. Speed Up the Simulation

If you want to see results faster:

```yaml
typing_speed: 200  # Faster typing
min_delay: 0       # No minimum delay
max_delay: 2       # Short pauses
```

### 2. Make It More Authentic

For a more human feel:

```yaml
typo_rate: 0.05      # More typos
rewrite_prob: 0.20   # More revisions
session_pattern: academic  # Realistic student schedule
```

### 3. Time Travel

To create a history that spans weeks:

```yaml
start: "2026-07-01 09:00"
end: "2026-07-31 17:00"  # A whole month!
```

### 4. Multiple Sessions

Write multiple documents with different patterns:

```bash
# Morning session
./ghostwriter.sh --config morning.yml

# Afternoon session
./ghostwriter.sh --config afternoon.yml
```

---

## Troubleshooting

### "Input file not found"
Make sure your input file exists and the path is correct in the config file.

### "Not inside a git repository"
Run `git init` in your project folder first.

### "Invalid date"
Use the format: `"YYYY-MM-DD HH:MM"` (24-hour time)

### Script stops unexpectedly
Use `--resume` to continue from where it stopped.

### Progress not saving
Check if the script has write permissions in the current directory.

---

## File Structure

After running GhostWriter, you'll have:

```
your-project/
├── ghostwriter.sh          # The script
├── ghostwriter.yml         # Your configuration
├── ghostwriter.log         # Detailed log (auto-generated)
├── .ghostwriter-progress   # Resume data (auto-generated)
├── my-draft.md            # Your input file
└── blog.md                # Your output file (with git history)
```

---

## Real-World Example

Let's say you have a 500-word article about Docker that you want to appear written over 2 days:

**Config (`ghostwriter.yml`):**
```yaml
input: docker-article.md
output: docker-blog.md
start: "2026-07-15 08:30"
end: "2026-07-16 17:45"
typing_speed: 45
session_pattern: coding
```

**Run it:**
```bash
./ghostwriter.sh --config ghostwriter.yml --verbose
```

**Result:** 
- 500 commits created
- Commit dates spread across 2 days
- Messages like "Explain container", "Add Dockerfile", "Show docker command"
- Natural pauses at lunch (12pm) and end of day (5pm)
- Looks like you wrote it over a productive 2-day period!

---

## Tips for Best Results

1. **Write your content first** - GhostWriter "replays" your writing
2. **Choose a realistic time window** - Don't claim you wrote 10,000 words in 2 hours
3. **Match session pattern to your persona** - Developer? Use `coding`. Student? Use `academic`.
4. **Check the log** - See exactly what happened during the simulation
5. **Practice with a small file first** - Test with 50 words before going big

---

## Safety & Best Practices

- ✅ Always work in a **git repository**
- ✅ Keep a **backup** of your original input file
- ✅ Run in a **clean environment** to avoid git conflicts
- ✅ **Commit your config** to remember your settings
- ✅ Use **.gitignore** to exclude `ghostwriter.log` and `.ghostwriter-progress`

---

## Need Help?

- **See the log file:** `cat ghostwriter.log`
- **View git history:** `git log --oneline --graph`
- **Check current progress:** `cat .ghostwriter-progress`
- **Start fresh:** Delete `.ghostwriter-progress` and run again

---

## Summary

GhostWriter transforms plain markdown into a rich git history that looks authentically human-written. With realistic typing, pauses, corrections, and work patterns, it's the perfect tool for creating believable project histories.

**Remember:** Your output file will have a complete git history with timestamps that match your configuration. Use it wisely! 😊

---

*Happy writing! Your ghostwriter awaits... 👻*

*Agentic JJ*