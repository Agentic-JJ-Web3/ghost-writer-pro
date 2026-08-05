# GhostWriter Pro

<div align="center">

**🖊️ Human-like Writing Simulation with Realistic Git History**

[![Bash](https://img.shields.io/badge/Bash-4.4%2B-green.svg)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Git](https://img.shields.io/badge/Git-2.0%2B-orange.svg)](https://git-scm.com/)

*Write once, create a realistic writing history*

</div>

---

## 📖 What is GhostWriter Pro?

GhostWriter Pro is a sophisticated bash script that transforms a markdown file into a realistic git commit history. It simulates the human writing process—complete with typos, corrections, coffee breaks, and natural writing rhythms—creating an authentic-looking timeline of your writing sessions.

**Think of it as a time machine for your writing process.** 🕐

### Why Use GhostWriter Pro?

- 🎯 **Create realistic git histories** for project portfolios
- 📝 **Demonstrate writing process** to clients or employers
- 🔧 **Test git visualization tools** with meaningful commit data
- 🏗️ **Build believable project timelines** for demos
- 📚 **Document your writing journey** with authentic timestamps

---

## ✨ Features

### Core Features
- ⌨️ **Character-by-character typing** - Each word appears realistically
- 🐛 **Typos and corrections** - Random typos (configurable) with automatic fixes
- 📊 **Progress tracking** - Visual progress bar with ETA
- 💾 **Resume support** - Ctrl+C saves progress, resume anytime
- 📝 **Markdown preservation** - Handles headings, lists, code blocks, tables

### Human-like Behavior
- ☕ **Coffee breaks** - Random 30-90 second pauses
- 🍽️ **Lunch breaks** - Automatic 1-hour pause at noon
- 🌙 **Overnight gaps** - Writing continues next morning
- ✍️ **Paragraph rewrites** - Occasional revisions (configurable)
- 🧠 **Context-aware commits** - Messages match what's being written

### Technical Features
- 📋 **Comprehensive logging** - Detailed `ghostwriter.log`
- ⚙️ **YAML configuration** - Easy to customize
- 🚦 **Interrupt handling** - Graceful Ctrl+C with progress save
- 📈 **Statistics** - Full summary after completion
- 🎨 **Colored output** - Beautiful terminal display

---

## 🚀 Quick Start

### Prerequisites

- **Bash** 4.4+ (macOS/Linux, or Git Bash on Windows)
- **Git** 2.0+ (installed and configured)
- A git repository (run `git init` if needed)

### Installation

```bash
# Clone the repository
git clone https://github.com/Agentic-JJ-Web3/ghost-writer-pro.git
cd ghostwriter

# Make the script executable
chmod +x ghostwriter.sh
```

### First Run

1. **Create a configuration file** (`ghostwriter.yml`):

```yaml
input: my-article.md
output: final-article.md
start: "2026-08-05 09:00"
end: "2026-08-06 17:00"
min_delay: 2
max_delay: 8
typing_speed: 50
typo_rate: 0.03
rewrite_prob: 0.15
session_pattern: balanced
```

2. **Create your content** (`my-article.md`):

```markdown
# My Great Article

## Introduction
This is the introduction to my amazing article.

## Main Content
Here I explain all the important concepts in detail.

## Conclusion
Finally, I wrap everything up with a strong conclusion.
```

3. **Run GhostWriter Pro**:

```bash
./ghostwriter.sh
```

4. **Watch the magic happen!** 🎩

```
[INFO] Loading configuration from: ghostwriter.yml
[INFO] Word count: 39
[INFO] Total timeline: 115200 seconds (32 hours)
Writing: ██████████████████████████████████████████████████ 100% 39/39 words
[SUCCESS] Writing complete!
```

---

## ⚙️ Configuration

### Complete Configuration File

```yaml
# GhostWriter Configuration
# ========================

# Input/Output files
input: my-article.md
output: final-article.md

# Time window (24-hour format)
start: "2026-08-05 09:00"
end: "2026-08-06 17:00"

# Writing parameters
min_delay: 2           # Minimum pause between words (seconds)
max_delay: 8           # Maximum pause between words (seconds)
typing_speed: 50       # Characters typed per second
typo_rate: 0.03        # Probability of typo per character (0-1)
rewrite_prob: 0.15     # Probability of paragraph rewrite (0-1)
session_pattern: balanced  # balanced | coding | academic | casual
```

### Session Patterns

| Pattern | Description | Working Hours |
|---------|-------------|---------------|
| `balanced` | Default office hours | 9am-12pm, 1pm-5pm, 7pm-10pm |
| `coding` | Developer schedule | 9am-12pm, 1:30pm-6pm, 8pm-11pm |
| `academic` | Student schedule | 8am-12pm, 2pm-5pm, 7pm-10pm |
| `casual` | Night owl schedule | 10am-2pm, 3pm-7pm, 9pm-1am |

---

## 🎮 Usage

### Basic Commands

```bash
# Run with default config (ghostwriter.yml)
./ghostwriter.sh

# Run with custom config
./ghostwriter.sh --config my-config.yml

# Resume after interruption
./ghostwriter.sh --resume

# Verbose mode (shows detailed output)
./ghostwriter.sh --verbose

# Show help
./ghostwriter.sh --help
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `--config, -c FILE` | Use specific configuration file |
| `--resume, -r` | Resume from last saved progress |
| `--verbose, -v` | Show detailed output |
| `--help, -h` | Display help message |

---

## 📊 Output & Logs

### What You'll See

**Progress Bar:**
```
Writing: ████████████░░░░░░░░ 42% 512/1231 words 3h 12m remaining
```

**Statistics:**
```
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

### Files Created

| File | Description |
|------|-------------|
| `final-article.md` | Your written document with git history |
| `ghostwriter.log` | Detailed execution log |
| `.ghostwriter-progress` | Resume data (auto-generated) |

---

## 🔧 Troubleshooting

### Common Issues

**"Input file not found"**
- Make sure your input file exists and the path is correct in config

**"Not inside a git repository"**
- Run `git init` in your project folder

**"Invalid date"**
- Use format: `"YYYY-MM-DD HH:MM"` (24-hour time)

**Script stops unexpectedly**
- Use `--resume` to continue from where it stopped

**Progress not saving**
- Check write permissions in the current directory

---

## 📂 File Structure

```
your-project/
├── ghostwriter.sh          # The script
├── ghostwriter.yml         # Your configuration
├── ghostwriter.log         # Detailed log (auto-generated)
├── .ghostwriter-progress   # Resume data (auto-generated)
├── my-article.md          # Your input file
└── final-article.md        # Your output file (with git history)
```

---

## 💡 Advanced Tips

### 1. Speed Up Simulation

For faster results:

```yaml
typing_speed: 200  # Faster typing
min_delay: 0       # No minimum delay
max_delay: 2       # Short pauses
```

### 2. Make It More Human

For more realistic writing:

```yaml
typo_rate: 0.05      # More typos
rewrite_prob: 0.20   # More revisions
session_pattern: academic  # Realistic schedule
```

### 3. Long-Term Projects

For histories spanning weeks:

```yaml
start: "2026-07-01 09:00"
end: "2026-07-31 17:00"  # A whole month!
```

### 4. Multiple Sessions

```bash
# Morning session
./ghostwriter.sh --config morning.yml

# Afternoon session
./ghostwriter.sh --config afternoon.yml
```

---

## 🎯 Use Cases

### Portfolio Projects
Create impressive git histories for your GitHub portfolio

### Client Demonstrations
Show clients your "writing process" with authentic timestamps

### Educational Examples
Demonstrate proper git commit practices

### Testing & Development
Test git visualization tools with realistic data

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/Agentic-JJ-Web3/ghostwriter.git
cd ghostwriter

# Make the script executable
chmod +x ghostwriter.sh

# Test with sample config
./ghostwriter.sh --verbose
```

### Coding Standards

- Follow Bash best practices
- Use `shellcheck` for linting
- Keep functions modular and well-documented
- Add tests for new features

---

## 📝 License

MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with ❤️ for the open-source community
- Inspired by realistic writing patterns
- Powered by Git's awesome version control

---

## 📬 Contact

- **Issues**: [GitHub Issues](https://github.com/Agentic-JJ-Web3/ghost-writer-pro/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Agentic-JJ-Web3/ghost-writer-pro/discussions)

---

<div align="center">

**Made with ❤️ and ⌨️ by Agentic**

*Happy writing! Your ghostwriter awaits... 👻*

</div>