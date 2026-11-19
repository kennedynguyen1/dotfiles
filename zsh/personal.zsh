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

# Set the caller's primary, tree, default_tip, and remote_tip from exact Git refs.
_wt_resolve() {
  local branch=$1 field checkout refs value ref
  [[ -n $branch && $(git check-ref-format --branch "$branch") == "$branch" ]] || return 1
  while IFS= read -r -d '' field; do
    case $field in
      'worktree '*)
        checkout=${field#worktree }
        [[ -n $primary ]] || primary=$checkout
        ;;
      "branch refs/heads/$branch")
        if [[ -n $tree ]]; then
          print -u2 -r -- "Multiple worktrees have $branch checked out. See git worktree list."
          return 1
        fi
        tree=$checkout
        ;;
    esac
  done < <(git worktree list --porcelain -z)
  [[ -n $primary ]] || return 1
  if [[ $branch == main || $tree == "$primary" ]]; then
    print -u2 -r -- "Protected branch or primary checkout: $branch"
    return 1
  fi

  if git remote get-url origin >/dev/null 2>&1; then
    refs=$(git ls-remote --symref origin HEAD "refs/heads/$branch") || return 1
    while IFS=$'\t' read -r value ref; do
      if [[ $ref == HEAD && $value == "ref: refs/heads/$branch" ]]; then
        print -u2 -r -- "Protected default branch of origin: $branch"
        return 1
      fi
      if [[ $ref == HEAD && $value != 'ref: '* ]]; then default_tip=$value; fi
      if [[ $ref == "refs/heads/$branch" ]]; then remote_tip=$value; fi
    done <<< "$refs"
  fi

  if [[ -n $tree ]]; then
    local top common
    common=$(git rev-parse --path-format=absolute --git-common-dir) &&
    top=$(git -C "$tree" rev-parse --show-toplevel) &&
      [[ ${top:A} == ${tree:A} && $(git -C "$tree" symbolic-ref -q HEAD) == "refs/heads/$branch" &&
         "$(git -C "$tree" rev-parse --path-format=absolute --git-common-dir)" -ef "$common" ]] || {
      print -u2 -r -- "Worktree is missing or no longer matches $branch: $tree"
      return 1
    }
  fi
  return 0
}

wt() {
  emulate -L zsh
  local agent_command
  case ${2-} in
    claude|codex) agent_command=$2 ;;
    CLAUDE) agent_command='claude --dangerously-skip-permissions' ;;
    CODEX) agent_command='codex --dangerously-bypass-approvals-and-sandbox' ;;
  esac
  if (( $# != 2 )) || [[ -z ${agent_command:-} ]]; then
    print -u2 'Usage: wt <branch> <claude|codex|CLAUDE|CODEX> (uppercase bypasses approvals)'
    return 2
  fi
  local branch=$1 agent=${2:l} primary='' tree='' default_tip='' remote_tip='' tool
  _wt_resolve "$branch" || return 1
  for tool in cmux nvim "$agent"; do
    if ! whence -p "$tool" >/dev/null; then
      print -u2 -r -- "Missing command: $tool"
      return 1
    fi
  done
  cmux ping >/dev/null || return 1

  if [[ -z $tree ]]; then
    tree="${primary:h}/wt-${branch//\//-}"
    if [[ -e $tree || -L $tree ]]; then
      print -u2 -r -- "Folder already exists: $tree"
      return 1
    fi
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git worktree add -- "$tree" "$branch" || return 1
    elif [[ -n $remote_tip ]]; then
      git fetch --no-tags origin "+refs/heads/${branch}:refs/remotes/origin/$branch" || return 1
      git worktree add --track -b "$branch" "$tree" "refs/remotes/origin/$branch" || return 1
    else
      [[ -n $default_tip ]] || { print -u2 'origin has no default commit'; return 1; }
      git fetch --no-tags --no-write-fetch-head origin "$default_tip" || return 1
      git worktree add --no-track -b "$branch" "$tree" "$default_tip" || return 1
    fi
  fi

  local layout='{"direction":"horizontal","children":[
    {"pane":{"surfaces":[{"type":"terminal","command":"nvim ."}]}},
    {"pane":{"surfaces":[{"type":"terminal","command":"'"$agent_command"'"}]}}
  ]}'
  cmux new-workspace --name "$branch" --cwd "$tree" --layout "$layout" --focus true || {
    print -u2 -r -- "Worktree available at $tree. To open it: cd ${(q)tree}"
    return 1
  }
}

dwt() {
  emulate -L zsh
  (( $# <= 1 )) || { print -u2 'Usage: dwt [branch]'; return 2; }
  local current branch primary='' tree='' default_tip='' remote_tip='' changes
  current=$(git rev-parse --show-toplevel) || return 1
  if (( $# )); then
    branch=$1
  else
    local first
    IFS= read -r -d '' first < <(git worktree list --porcelain -z) || return 1
    if [[ $current -ef ${first#worktree } ]]; then
      git worktree list
      print 'Run dwt <branch> to remove a task checkout.'
      return 0
    fi
    branch=$(git branch --show-current) || return 1
    [[ -n $branch ]] || {
      print -u2 'Detached HEAD. Use git worktree list to inspect the checkouts.'
      return 1
    }
  fi
  _wt_resolve "$branch" || return 1
  [[ -n $tree ]] || { print -u2 -r -- "No worktree for branch: $branch"; return 1; }
  changes=$(git -C "$tree" status --porcelain --untracked-files=normal --ignore-submodules=none) || return 1
  if [[ -n $changes ]]; then
    print -u2 -rl -- "Worktree has local changes: $tree" "$changes"
    return 1
  fi
  local previous=$PWD
  if [[ $current -ef $tree ]]; then builtin cd -- "$primary" || return 1; fi
  if ! git -C "$primary" worktree remove -- "$tree"; then
    [[ $PWD == "$previous" ]] || builtin cd -- "$previous"
    return 1
  fi
  print -r -- "Removed $tree. Kept branch $branch."
}
