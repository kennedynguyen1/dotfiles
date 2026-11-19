#!/bin/bash
# Exercise setup in a disposable home. Only the Kickstart clone needs network.
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd -P)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$HOME/.config" ZDOTDIR="$HOME"
mkdir -p "$HOME" "$scratch/bin" "$scratch/repo"
cp -R "$repo/Brewfile" "$repo/setup" "$repo/ghostty" "$repo/zsh" "$scratch/repo/"
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
./setup
[[ -L "$HOME/.p10k.zsh" && "$HOME/.p10k.zsh" -ef zsh/p10k.zsh ]]
[[ -L "$XDG_CONFIG_HOME/ghostty/config" && "$XDG_CONFIG_HOME/ghostty/config" -ef ghostty/config ]]
[[ -L "$XDG_CONFIG_HOME/zsh/personal.zsh" && "$XDG_CONFIG_HOME/zsh/personal.zsh" -ef zsh/personal.zsh ]]
[[ "$(git -C "$XDG_CONFIG_HOME/nvim" rev-parse HEAD)" == 8e35dbedb7966e3a95e1f26f9fc1179ab6c68db4 ]]
echo '# local edit' >> "$HOME/.p10k.zsh"
grep -qF '# local edit' zsh/p10k.zsh
echo '-- personal nvim change' >> "$XDG_CONFIG_HOME/nvim/init.lua"
cp "$HOME/.zshrc" "$scratch/zshrc"
./setup
cmp "$HOME/.zshrc" "$scratch/zshrc"
grep -qF -- '-- personal nvim change' "$XDG_CONFIG_HOME/nvim/init.lua"
[[ "$(grep -c '^bundle install --no-upgrade' "$HOME/brew.calls")" == 1 ]]
echo 'Setup checks passed.'
