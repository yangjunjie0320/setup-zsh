# setup-zsh

Bootstrap zsh + Vim dotfiles with oh-my-zsh plugins and the powerlevel10k theme. Supports dry-run, update, and uninstall.

## Structure
- `setup.sh` – bootstrap script (`--dry-run`, `--update`, `--uninstall`)
- `zsh/` – shell configs (`zshrc`, `zprofile`, `local.zsh.example`)
- `vim/vimrc` – Vim defaults
- `links.txt` – symlink manifest (`src dst`, dst relative to `$HOME`)
- `plugins/plugins.txt` – plugin list cloned into `$ZSH_CUSTOM/plugins`
- `themes.txt` – theme list cloned into `$ZSH_CUSTOM/themes`

## Prerequisites
- zsh installed
- curl, git available
- A [Nerd Font](https://www.nerdfonts.com/) in your terminal for powerlevel10k icons to render correctly

## Usage
```bash
curl -fsSL https://raw.githubusercontent.com/yangjunjie0320/setup-zsh/main/setup.sh | bash
```

Other modes (run from a cloned checkout):
```bash
./setup.sh --dry-run    # print every action without changing anything
./setup.sh --update     # git pull existing plugins/themes and re-link
./setup.sh --uninstall  # remove created symlinks and restore .bak backups
```

## Customization
- Plugins: edit `plugins/plugins.txt` then rerun `setup.sh`.
- Themes: edit `themes.txt` (defaults to powerlevel10k).
- Symlinks: edit `links.txt` to add/remove managed dotfiles.
- Machine-specific tweaks: copy `zsh/local.zsh.example` to `~/.zsh/local.zsh`.
- Vim: adjust `vim/vimrc`.

## Notes
- If a target file exists and is not a symlink, `setup.sh` backs it up to `<file>.bak`
  (or a timestamped `<file>.bak.<ts>` if a `.bak` already exists) before linking.
- powerlevel10k runs its configuration wizard on first launch; the generated
  `~/.p10k.zsh` is sourced automatically on later sessions.
- Restart the terminal after running to load the new config.
