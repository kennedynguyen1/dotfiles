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

wt() {
  emulate -L zsh
  if (( $# != 2 )) || [[ $2 != (claude|codex) ]]; then
    print -u2 'Usage: wt <new-branch> <claude|codex>'
    return 2
  fi
  local branch=$1 agent=$2 root tree tool
  [[ $(git check-ref-format --branch "$branch") == "$branch" && -n $branch ]] || return 1
  IFS= read -rd '' root < <(git worktree list --porcelain -z) || return 1
  root=${root#worktree }
  tree="${root}-${branch//\//-}"
  if [[ -e $tree || -L $tree ]] || git show-ref --verify --quiet "refs/heads/$branch"; then
    print -u2 -r -- "Branch or folder already exists: $branch / $tree"
    return 1
  fi
  for tool in cmux nvim "$agent"; do
    if ! whence -p "$tool" >/dev/null; then
      print -u2 -r -- "Missing command: $tool"
      return 1
    fi
  done
  cmux ping >/dev/null || return 1

  local refs sha ref base=''
  refs=$(git ls-remote --exit-code origin HEAD "refs/heads/$branch") || return 1
  while IFS=$'\t' read -r sha ref; do
    if [[ $ref == "refs/heads/$branch" ]]; then
      print -u2 -r -- "Branch already exists on origin: $branch"
      return 1
    fi
    [[ $ref == HEAD ]] && base=$sha
  done <<< "$refs"
  [[ -n $base ]] || { print -u2 'origin has no default commit'; return 1; }
  git fetch --no-tags --no-write-fetch-head origin "$base" || return 1
  git worktree add --no-track -b "$branch" "$tree" "$base" || return 1

  local layout='{"direction":"horizontal","children":[
    {"pane":{"surfaces":[{"type":"terminal","command":"nvim ."}]}},
    {"pane":{"surfaces":[{"type":"terminal","command":"'"$agent"'"}]}}
  ]}'
  cmux new-workspace --name "$branch" --cwd "$tree" --layout "$layout" --focus true || {
    print -u2 -r -- "Worktree created at $tree. To open it: cd ${(q)tree}"
    return 1
  }
}
