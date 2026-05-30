#!/usr/bin/env bash
set -e

# =====================================
# setup-zsh bootstrap script
# =====================================

# ---------- mode ----------
MODE="apply" # apply | dry-run | update | uninstall

case "${1:-}" in
  --dry-run|--check)
    MODE="dry-run"
    ;;
  --update)
    MODE="update"
    ;;
  --uninstall)
    MODE="uninstall"
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1"
    echo "Usage: setup.sh [--dry-run|--update|--uninstall]"
    exit 1
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

# ---------- uninstall: remove managed symlinks and restore backups ----------
uninstall_links() {
  local manifest="$SETUP_DIR/links.txt"
  if [[ ! -f "$manifest" ]]; then
    log "No links.txt found, nothing to uninstall"
    return
  fi

  while read -r src dst || [[ -n "$src" ]]; do
    [[ -z "$src" || "$src" =~ ^# ]] && continue
    local target="$HOME/$dst"

    if [[ -L "$target" ]]; then
      if [[ "$(readlink "$target")" == "$SETUP_DIR/"* ]]; then
        log "Removing symlink $target"
        run rm "$target"
      else
        log "Skipping $target (symlink not managed by setup-zsh)"
        continue
      fi
    elif [[ -e "$target" ]]; then
      log "Skipping $target (not a symlink)"
      continue
    fi

    if [[ -e "${target}.bak" ]]; then
      log "Restoring ${target}.bak to $target"
      run mv "${target}.bak" "$target"
    fi
  done < "$manifest"
}

if [[ "$MODE" == "uninstall" ]]; then
  log "Uninstalling setup-zsh symlinks"
  uninstall_links
  log "Uninstall complete. oh-my-zsh and cloned plugins/themes were left in place;"
  log "remove ~/.oh-my-zsh and $REPO_DIR manually for a full cleanup."
  exit 0
fi

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
  # Bypass run(): the install.sh is fetched via command substitution, so we
  # must not let dry-run hit the network or dump the installer as an argument.
  if [[ "$MODE" == "dry-run" ]]; then
    echo "[dry-run] install oh-my-zsh via ohmyzsh/tools/install.sh"
  else
    env KEEP_ZSHRC=yes RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
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

# ---------- 3. install plugins and themes ----------
# install_repo <kind> <dest_base> <name> <repo>
install_repo() {
  local kind="$1"
  local dest="$2/$3"
  local name="$3"
  local repo="$4"

  if [[ ! -d "$dest" ]]; then
    log "Installing $kind: $name"
    run git clone "$repo" "$dest" || log "WARN: failed to clone $kind $name, skipping"
  elif [[ "$MODE" == "update" ]]; then
    log "Updating $kind: $name"
    run git -C "$dest" pull --ff-only || log "WARN: failed to update $kind $name, skipping"
  else
    log "$kind already exists: $name"
  fi
}

# install_from_manifest <kind> <dest_base> <manifest>
install_from_manifest() {
  local kind="$1"
  local dest_base="$2"
  local manifest="$3"

  if [[ ! -f "$manifest" ]]; then
    log "No $(basename "$manifest") found, skipping $kind install"
    return
  fi

  while read -r name repo || [[ -n "$name" ]]; do
    [[ -z "$name" || "$name" =~ ^# ]] && continue
    install_repo "$kind" "$dest_base" "$name" "$repo"
  done < "$manifest"
}

install_from_manifest "plugin" "$ZSH_CUSTOM/plugins" "$SETUP_DIR/plugins/plugins.txt"
install_from_manifest "theme"  "$ZSH_CUSTOM/themes"  "$SETUP_DIR/themes.txt"

# ---------- done ----------
log "Setup completed (mode: $MODE)"
log "Restart terminal or re-login to take effect"
