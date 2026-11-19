#!/bin/bash
# Exercise setup in a disposable home.
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd -P)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$HOME/.config" ZDOTDIR="$HOME"
mkdir -p "$HOME" "$scratch/bin" "$scratch/repo"
cp -R "$repo/Brewfile" "$repo/setup" "$repo/ghostty" "$repo/zsh" "$repo/nvim" "$scratch/repo/"
cd "$scratch/repo"
cat > "$scratch/bin/brew" <<'BREW'
#!/bin/sh
echo "$*" >> "$HOME/brew.calls"
case "$1 $2" in
  'bundle check') test -e "$HOME/installed" ;;
  'bundle install') touch "$HOME/installed" ;;
  *) exit 1 ;;
esac
BREW
chmod +x "$scratch/bin/brew"
export PATH="$scratch/bin:$PATH"

echo 'local config' > "$HOME/.p10k.zsh"
if ./setup > "$scratch/conflict" 2>&1; then exit 1; fi
grep -Fq "$HOME/.p10k.zsh" "$scratch/conflict"
grep -Fq 'zsh/p10k.zsh' "$scratch/conflict"
if grep -Fq 'local config' "$scratch/conflict"; then exit 1; fi
[[ "$(cat "$HOME/.p10k.zsh")" == 'local config' && ! -e "$HOME/brew.calls" ]]

cp zsh/p10k.zsh "$HOME/.p10k.zsh"
mkdir -p "$XDG_CONFIG_HOME/nvim"
echo '-- existing config' > "$XDG_CONFIG_HOME/nvim/init.lua"
if ./setup > "$scratch/conflict" 2>&1; then exit 1; fi
grep -Fq "$XDG_CONFIG_HOME/nvim" "$scratch/conflict"
[[ "$(cat "$XDG_CONFIG_HOME/nvim/init.lua")" == '-- existing config' && ! -e "$HOME/brew.calls" ]]
mv "$XDG_CONFIG_HOME/nvim" "$scratch/nvim-backup"
./setup
[[ -L "$HOME/.p10k.zsh" && "$HOME/.p10k.zsh" -ef zsh/p10k.zsh ]]
[[ -L "$XDG_CONFIG_HOME/ghostty/config" && "$XDG_CONFIG_HOME/ghostty/config" -ef ghostty/config ]]
[[ -L "$XDG_CONFIG_HOME/zsh/personal.zsh" && "$XDG_CONFIG_HOME/zsh/personal.zsh" -ef zsh/personal.zsh ]]
[[ -L "$XDG_CONFIG_HOME/nvim" && "$XDG_CONFIG_HOME/nvim" -ef nvim ]]
[[ -f "$XDG_CONFIG_HOME/nvim/lua/custom/plugins/diffview.lua" && -f "$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json" ]]
echo '# local edit' >> "$HOME/.p10k.zsh"
grep -qF '# local edit' zsh/p10k.zsh
echo '-- personal nvim change' >> "$XDG_CONFIG_HOME/nvim/init.lua"
cp "$HOME/.zshrc" "$scratch/zshrc"
./setup
cmp "$HOME/.zshrc" "$scratch/zshrc"
grep -qF -- '-- personal nvim change' nvim/init.lua
[[ "$(grep -c '^bundle install --no-upgrade' "$HOME/brew.calls")" == 1 ]]
echo 'Setup checks passed.'
