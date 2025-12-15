# setup-zsh

Bootstrap zsh + Vim dotfiles with oh-my-zsh plugins. Supports dry-run.

## Structure
- `setup.sh` – bootstrap script (supports `--dry-run`)
- `zsh/` – shell configs (`zshrc`, `zprofile`, `aliases.zsh`, `local.zsh.example`)
- `vim/vimrc` – Vim defaults
- `plugins/plugins.txt` – plugin list cloned into `$ZSH_CUSTOM/plugins`

## Prerequisites
- zsh installed
- curl, git available

## Usage
```bash
curl -fsSL https://raw.githubusercontent.com/yangjunjie0320/setup-zsh/main/setup.sh | bash
```

## Customization
- Plugins: edit `plugins/plugins.txt` then rerun `setup.sh`.
- Machine-specific tweaks: copy `zsh/local.zsh.example` to `~/.zsh/local.zsh`.
- Vim: adjust `vim/vimrc`.

## Notes
- If a target file exists and is not a symlink, `setup.sh` skips it to avoid overwriting.
- Restart the terminal after running to load the new config.

