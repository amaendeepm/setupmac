#!/usr/bin/env bash
# =============================================================================
# bmm_revised.sh — Mac Developer Machine Setup
# Amandeep Midha | Hybrid Greentech / Personal Dev Workstation
# Updated: 2026-05 — Adds VSCode (latest), OpenCode, AWS Bedrock/CLI v2,
#          Postman, Rust toolchain via rustup (with clippy/fmt), cleanup pass
# =============================================================================

set -euo pipefail   # fail fast: exit on error, unset var, or pipe failure
IFS=$'\n\t'

# ── Colour helpers ─────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERR]${NC}   $*" >&2; }

info "========================================="
info "  Mac Developer Machine Setup — Starting "
info "========================================="

# ── 0. Xcode Command Line Tools ────────────────────────────────────────────
# Must come before Homebrew; safe to re-run (no-op if already present)
if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode Command Line Tools..."
  xcode-select --install
  # Wait for CLT to finish before Homebrew
  until xcode-select -p &>/dev/null; do sleep 5; done
fi

# ── 1. Homebrew ────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add Homebrew to PATH on Apple Silicon (no-op on Intel)
if [[ "$(uname -m)" == "arm64" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # Persist to shell profile if not already there
  BREW_ENV_LINE='eval "$(/opt/homebrew/bin/brew shellenv)"'
  for PROFILE in "$HOME/.zprofile" "$HOME/.bash_profile"; do
    grep -qF "$BREW_ENV_LINE" "$PROFILE" 2>/dev/null || echo "$BREW_ENV_LINE" >> "$PROFILE"
  done
fi

info "Updating Homebrew..."
brew update && brew upgrade   # upgrade all stale formulae up front

# ── CLEANUP — remove legacy / duplicate formula installs ──────────────────
info "Removing legacy/conflicting formulae..."
# 'rust' formula conflicts with rustup-managed toolchain; rustup is canonical
brew uninstall --ignore-dependencies rust 2>/dev/null || true
# terraform@1.2 is pinned-old; replace with latest or use tfenv
brew uninstall --ignore-dependencies terraform@1.2 2>/dev/null || true
# openvpn formula duplicates the cask openvpn-connect
brew uninstall --ignore-dependencies openvpn 2>/dev/null || true
# wireshark formula duplicates the chmodbpf cask
brew uninstall --ignore-dependencies wireshark 2>/dev/null || true
# 'go install encoding/xml' is invalid (it's stdlib) — removed entirely
# awscurl clashes with AWS CLI v2 workflows; keep if specifically needed
brew uninstall --ignore-dependencies awscurl 2>/dev/null || true

# ── 2. GNU Core Utilities ──────────────────────────────────────────────────
info "Installing GNU core utilities..."
brew install coreutils gnu-sed gnu-tar gnu-indent gnu-which gnu-getopt findutils grep

# ── 3. Core Dev Formulae ───────────────────────────────────────────────────
info "Installing core dev formulae..."
FORMULAE=(
  # Source control
  git
  gh

  # Build tooling
  cmake ninja libtool llvm gcc binutils ccache gettext

  # Languages / runtimes
  go
  node          # replaces 'npm' formula — brings both node and npm
  python@3.12   # explicit minor version; avoids 'python'/'python3' ambiguity

  # AWS — CLI v2 is the cask 'awscli'; the formula 'awscli' is v2 on Homebrew
  awscli        # AWS CLI v2 (Homebrew formula, kept current via brew upgrade)

  # Data / API / messaging
  jq
  postgresql@16
  rabbitmq
  # Redpanda (Kafka-compatible) — via tap below

  # Infrastructure
  terraform             # latest; use tfenv cask if you need multi-version
  openssl
  libxml2
  pipx                  # manages Python CLI tools in isolated envs

  # Utilities
  tree
  vim
  wget
  libserdes
)

brew install "${FORMULAE[@]}"

# Redpanda (Kafka replacement, single binary)
brew tap redpanda-data/tap
brew install redpanda-data/tap/redpanda

# ActiveMQ — keep if needed for legacy BRS/RSM message broker testing
brew install apache-activemq

# Wireshark (formula — no capture yet; capture handled by cask below)
# brew install wireshark  # omitted — cask wireshark-chmodbpf covers both UI + capture

# ── 4. Rust Toolchain via rustup ───────────────────────────────────────────
# rustup is the canonical way; gives you clippy, rustfmt, rust-analyzer, cargo
info "Installing Rust toolchain via rustup..."
if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi

# Source cargo env for the rest of this session
# shellcheck source=/dev/null
source "$HOME/.cargo/env"

info "Updating Rust toolchain and installing components..."
rustup update stable
rustup component add clippy rustfmt rust-analyzer rust-src
# rust-analyzer also available as a brew formula (binary); cask rustrover has its own bundled one
# Fix cargo ownership
sudo chown -R "$(whoami)" "$HOME/.cargo"

# Useful cargo tools
info "Installing Cargo tools..."
cargo install cargo-edit       # cargo add / cargo rm / cargo upgrade
cargo install cargo-watch      # cargo watch -x check
cargo install cargo-nextest    # faster test runner (replaces cargo test)
cargo install cargo-audit      # security advisory checks
cargo install cargo-expand     # macro expansion
cargo install tokio-console    # async runtime debugging
# sccache — speeds up incremental Rust + C builds
brew install sccache
export RUSTC_WRAPPER=sccache

# ── 5. AWS Bedrock & AI/ML tooling ────────────────────────────────────────
info "Setting up AWS Bedrock / AI tooling..."

# AWS CLI v2 already installed above via formula
# AWS Vault — secure credential management (never plain-text keys)
brew install --cask aws-vault
# AWS SAM CLI — serverless + Lambda local testing
brew tap aws/tap
brew install aws-sam-cli
# AWS CDK (TypeScript-first IaC; works with Bedrock constructs)
npm install -g aws-cdk
# Bedrock Python SDK convenience setup (via pipx to keep global env clean)
pipx install boto3       2>/dev/null || pipx upgrade boto3
# boto3 includes bedrock-runtime; just import:
#   import boto3; client = boto3.client("bedrock-runtime", region_name="us-east-1")

# OpenCode — AI-powered terminal coding agent (uses Bedrock / Anthropic / OpenAI)
info "Installing OpenCode..."
if ! command -v opencode &>/dev/null; then
  # Official installer
  curl -fsSL https://opencode.ai/install | bash
fi
# If the above URL changes, fallback: npm install -g opencode-ai

# ── 6. Homebrew Cask Applications ─────────────────────────────────────────
info "Installing Cask Applications..."
CASKS=(
  # Editors / IDEs
  visual-studio-code      # VSCode — auto-updates itself; brew cask keeps installer fresh
  rustrover               # JetBrains Rust IDE
  intellij-idea-ce        # JetBrains Java/Kotlin IDE
  pycharm-ce              # JetBrains Python IDE

  # API / DB tools
  postman                 # REST/gRPC/GraphQL testing (primary)
  insomnia                # Alternative API client
  dbeaver-community       # DB universal viewer
  db-browser-for-sqlite   # SQLite viewer
  soapui                  # SOAP/XML API testing (BRS/RSM compliance testing)

  # Cloud / DevOps
  docker                  # Docker Desktop
  aws-vault               # already installed above — harmless duplicate guard

  # Browsers
  google-chrome
  firefox

  # Productivity / Comms
  microsoft-outlook
  microsoft-teams
  slack
  canva
  drawio

  # Security / Network
  wireshark-chmodbpf      # Wireshark + capture permissions
  openvpn-connect
  tunnelblick             # OpenVPN alternative (useful for .ovpn configs)

  # File management / Encryption
  tresorit
  commander-one

  # Misc dev utilities
  homebank                # Personal finance (optional; keep if used)
)

for CASK in "${CASKS[@]}"; do
  if brew list --cask "$CASK" &>/dev/null; then
    info "  [skip] $CASK already installed"
  else
    brew install --cask "$CASK" || warn "  Failed to install cask: $CASK — continuing"
  fi
done

# ── 7. VSCode Extensions ───────────────────────────────────────────────────
info "Installing VSCode extensions..."
VSC=( 
  # Rust
  rust-lang.rust-analyzer
  serayuzgur.crates          # Cargo.toml dependency version hints
  vadimcn.vscode-lldb        # LLDB debugger for Rust
  tamasfe.even-better-toml   # TOML support

  # Python / Data
  ms-python.python
  ms-python.black-formatter
  ms-toolsai.jupyter

  # AWS / Cloud
  amazonwebservices.aws-toolkit-vscode
  ms-azuretools.vscode-docker

  # General dev
  eamodio.gitlens
  mhutchie.git-graph
  esbenp.prettier-vscode
  dbaeumer.vscode-eslint
  ms-vscode-remote.remote-containers   # Dev Containers
  ms-vscode-remote.remote-ssh
  redhat.vscode-xml                    # CIM XML / DataHub3 schemas
  redhat.vscode-yaml
  jebbs.plantuml

)
for EXT in "${VSC[@]}"; do
  code --install-extension "$EXT" --force 2>/dev/null || warn "  VSCode ext failed: $EXT"
done

# ── 8. Oh My Zsh ──────────────────────────────────────────────────────────
info "Installing Oh My Zsh (if not present)..."
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ── 9. Python tooling via pipx ────────────────────────────────────────────
info "Installing Python CLI tools via pipx (isolated envs, no sudo pip)..."
# NOTE: 'sudo python3 get-pip.py' removed — pipx handles this cleanly
pipx ensurepath
PYTOOLS=(
  # AWS
  awsume              # quick role-switching for AWS CLI
  # Data / API
  httpie              # modern curl replacement (http / https commands)
  # Dev tools
  black
  ruff
  mypy
  # Azure kept for reference — uncomment if still needed
  # azure-cli
)
for TOOL in "${PYTOOLS[@]}"; do
  pipx install "$TOOL" 2>/dev/null || pipx upgrade "$TOOL" || true
done

# Azure SDK packages — keep in a dedicated venv or project; avoid global pip
# If you genuinely need them globally:
# pipx inject boto3 azure-mgmt-compute azure-mgmt-storage ... etc.

# ── 10. Node / npm global packages ────────────────────────────────────────
info "Installing global npm packages..."
npm install -g marked
npm install -g aws-cdk        # already done above; idempotent

# ── 11. Go tooling ────────────────────────────────────────────────────────
info "Installing Go packages..."
# 'go install encoding/xml' was invalid (it's stdlib) — removed
go install github.com/tiaguinho/gosoap@latest

# ── 12. Terraform autocomplete ────────────────────────────────────────────
info "Enabling Terraform autocomplete..."
terraform -install-autocomplete 2>/dev/null || true

# ── 13. GitHub CLI extensions ─────────────────────────────────────────────
info "Installing GitHub CLI extensions..."
gh ext install advanced-security/gh-sbom || true

# ── 14. macOS System Defaults ─────────────────────────────────────────────
info "Applying macOS system defaults..."

# Security
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Keyboard / UX
defaults write NSGlobalDomain KeyRepeat -int 5
defaults write NSGlobalDomain InitialKeyRepeat -int 20

# Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Screenshots to ~/Desktop/Screenshots
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture location "$HOME/Desktop/Screenshots"

# ── 15. Dock ──────────────────────────────────────────────────────────────
info "Configuring Dock..."
dock_item() {
  printf '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>%s</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>' "$1"
}

defaults delete com.apple.dock persistent-apps    2>/dev/null || true
defaults delete com.apple.dock recent-apps        2>/dev/null || true
defaults delete com.apple.dock persistent-others  2>/dev/null || true

defaults write com.apple.dock persistent-apps -array \
  "$(dock_item /Applications/Visual\ Studio\ Code.app)" \
  "$(dock_item /Applications/Postman.app)" \
  "$(dock_item /Applications/Google\ Chrome.app)" \
  "$(dock_item /Applications/Slack.app)" \
  "$(dock_item /Applications/Microsoft\ Outlook.app)" \
  "$(dock_item /Applications/Microsoft\ Teams.app)" \
  "$(dock_item /Applications/draw.io.app)" \
  "$(dock_item /Applications/DBeaver.app)" \
  "$(dock_item /Applications/Canva.app)" \
  "$(dock_item /Applications/Tresorit.app)"

killall Dock

# ── 16. Final brew cleanup ────────────────────────────────────────────────
info "Final Homebrew cleanup..."
brew cleanup --prune=all
brew autoremove   # remove unused dependencies

# ── 17. Shell PATH summary ────────────────────────────────────────────────
info "Appending tool PATHs to ~/.zshrc (idempotent)..."
ZSHRC="$HOME/.zshrc"

append_if_absent() {
  grep -qF "$1" "$ZSHRC" 2>/dev/null || echo "$1" >> "$ZSHRC"
}

# Homebrew (Apple Silicon)
[[ "$(uname -m)" == "arm64" ]] && \
  append_if_absent 'eval "$(/opt/homebrew/bin/brew shellenv)"'

# Cargo / Rust
append_if_absent 'source "$HOME/.cargo/env"'

# sccache for Rust builds
append_if_absent 'export RUSTC_WRAPPER=sccache'

# Go
append_if_absent 'export PATH="$HOME/go/bin:$PATH"'

# pipx
append_if_absent 'export PATH="$HOME/.local/bin:$PATH"'

# GNU tools (make them default without g- prefix)
append_if_absent 'export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"'
append_if_absent 'export PATH="$(brew --prefix)/opt/findutils/libexec/gnubin:$PATH"'
append_if_absent 'export PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH"'
append_if_absent 'export PATH="$(brew --prefix)/opt/grep/libexec/gnubin:$PATH"'

# OpenSSL (needed by some Python / Rust crates)
append_if_absent 'export LDFLAGS="-L$(brew --prefix openssl)/lib"'
append_if_absent 'export CPPFLAGS="-I$(brew --prefix openssl)/include"'

# AWS region default (edit as needed)
append_if_absent 'export AWS_DEFAULT_REGION="eu-west-1"'

# ── Done ──────────────────────────────────────────────────────────────────
echo ""
info "=============================================================="
info "  Mac setup complete. Open a new terminal to pick up PATHs."
info "  Run: source ~/.zshrc   (or restart terminal)"
info ""
info "  Post-setup checklist:"
info "  1. aws configure  (or use aws-vault add <profile>)"
info "  2. opencode auth  (configure Bedrock or Anthropic key)"
info "  3. gh auth login"
info "  4. rustup show    (verify stable toolchain + components)"
info "  5. cargo clippy --all-targets --all-features  (test Rust linting)"
info "  6. code --list-extensions  (verify VSCode extensions installed)"
info "  7. docker run hello-world  (verify Docker Desktop running)"
info "=============================================================="
