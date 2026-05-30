#!/usr/bin/env bash
set -e

# =====================================
# setup-zsh bootstrap script
# =====================================

# ---------- mode ----------
MODE="apply" # apply | dry-run

case "${1:-}" in
  --dry-run|--check)
    MODE="dry-run"
    ;;
esac

log() {
  echo "==> $*"
}

run() {
  if [[ "$MODE" == "dry-run" ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

# ---------- paths ----------
SETUP_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_URL="${SETUP_REPO_URL:-https://github.com/yangjunjie0320/setup-zsh.git}"
REPO_DIR="${SETUP_DEST_DIR:-$HOME/.setup-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ---------- ensure repo contents (for curl piping) ----------
if [[ ! -d "$SETUP_DIR/zsh" || ! -f "$SETUP_DIR/setup.sh" ]]; then
  log "Repository files missing in current context; cloning to $REPO_DIR"

  if [[ ! -d "$REPO_DIR/.git" ]]; then
    run git clone "$REPO_URL" "$REPO_DIR"
  else
    log "Existing repo found at $REPO_DIR, reusing"
  fi
  export SETUP_DIR="$REPO_DIR"
fi

echo "SETUP_DIR: $SETUP_DIR"

# ---------- 0. require zsh, git and curl----------
if ! command -v zsh >/dev/null 2>&1; then
  echo "ERROR: zsh not found. Please install zsh first."
  exit 1
fi
log "zsh found: $(command -v zsh)"

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git not found. Please install git first."
  exit 1
fi
log "git found: $(command -v git)"

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl not found. Please install curl first."
  exit 1
fi
log "curl found: $(command -v curl)"

# ---------- 1. install oh-my-zsh ----------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing oh-my-zsh"
  run env KEEP_ZSHRC=yes RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log "oh-my-zsh already installed"
fi

# ---------- 2. safe symlink ----------
safe_link() {
  local src="$1"
  local dst="$2"

  if [[ -e "$dst" && ! -L "$dst" ]]; then
    local bak="${dst}.bak"
    if [[ -e "$bak" ]]; then
      bak="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    fi
    log "Backing up existing $dst to $bak"
    run mv "$dst" "$bak"
  fi

  run ln -sf "$src" "$dst"
  log "Linked $dst"
}

LINK_FILE="$SETUP_DIR/links.txt"

if [[ -f "$LINK_FILE" ]]; then
  while read -r src dst || [[ -n "$src" ]]; do
    [[ -z "$src" || "$src" =~ ^# ]] && continue
    safe_link "$SETUP_DIR/$src" "$HOME/$dst"
  done < "$LINK_FILE"
else
  log "No links.txt found, skipping symlink setup"
fi

# ---------- 3. install plugins ----------
install_plugin() {
  local name="$1"
  local repo="$2"

  if [[ ! -d "$ZSH_CUSTOM/plugins/$name" ]]; then
    log "Installing plugin: $name"
    run git clone "$repo" "$ZSH_CUSTOM/plugins/$name"
  else
    log "Plugin already exists: $name"
  fi
}

PLUGIN_FILE="$SETUP_DIR/plugins/plugins.txt"

if [[ -f "$PLUGIN_FILE" ]]; then
  while read -r name repo; do
    [[ -z "$name" || "$name" =~ ^# ]] && continue
    install_plugin "$name" "$repo"
  done < "$PLUGIN_FILE"
else
  log "No plugins.txt found, skipping plugin install"
fi

# ---------- done ----------
log "Setup completed (mode: $MODE)"
log "Restart terminal or re-login to take effect"
