# Loaded from the machine's interactive .zshrc.
if [[ -n ${HOMEBREW_PREFIX:-} ]] || (( $+commands[brew] )); then
  typeset _personal_brew_share="${HOMEBREW_PREFIX:-$(brew --prefix)}/share"
  source "$_personal_brew_share/powerlevel10k/powerlevel10k.zsh-theme"
  [[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh
  source "$_personal_brew_share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  eval "$(zoxide init zsh)"
  source "$_personal_brew_share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  unset _personal_brew_share
fi
