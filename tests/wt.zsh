#!/bin/zsh -f
set -eu
dotfiles=${0:A:h:h}
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
scratch=${scratch:A}
mkdir "$scratch/bin"
export PATH="$scratch/bin:/usr/bin:/bin"
unset HOMEBREW_PREFIX
source "$dotfiles/zsh/personal.zsh"

# Stand in for cmux's GUI socket and agent binaries.
for tool in nvim claude codex; do ln -s /usr/bin/true "$scratch/bin/$tool"; done
cat > "$scratch/bin/cmux" <<'PY'
#!/usr/bin/env python3
import json, os, sys
if sys.argv[1:] == ["ping"]:
    sys.exit(0)
assert sys.argv[1] == "new-workspace"
args = dict(zip(sys.argv[2::2], sys.argv[3::2]))
assert args["--cwd"] == os.environ["EXPECTED_TREE"]
assert args["--name"] == os.environ["EXPECTED_BRANCH"]
assert args["--focus"] == "true"
layout = json.loads(args["--layout"])
assert layout["direction"] == "horizontal"
assert [p["pane"]["surfaces"][0]["command"] for p in layout["children"]] == [
    "nvim .", {
        "claude": "claude",
        "codex": "codex",
        "CLAUDE": "claude --dangerously-skip-permissions",
        "CODEX": "codex --dangerously-bypass-approvals-and-sandbox",
    }[os.environ["EXPECTED_AGENT"]]
]
sys.exit(int(os.environ.get("FAIL_LAUNCH", "0")))
PY
chmod +x "$scratch/bin/cmux"
git init -q -b trunk "$scratch/upstream"
git -C "$scratch/upstream" -c user.name=Test -c user.email=test@example.org commit -qm first --allow-empty
git clone -q "$scratch/upstream" "$scratch/my app"
cd "$scratch/my app"
git switch -qc local-feature
mkdir src
cd src
git -C "$scratch/upstream" -c user.name=Test -c user.email=test@example.org commit -qm second --allow-empty
latest=$(git -C "$scratch/upstream" rev-parse HEAD)

for agent in claude codex; do
  export EXPECTED_AGENT=$agent EXPECTED_BRANCH="fix/$agent" EXPECTED_TREE="$scratch/wt-fix-$agent"
  wt "$EXPECTED_BRANCH" "$agent"
  [[ $(git -C "$EXPECTED_TREE" rev-parse HEAD) == "$latest" ]]
  [[ $(git -C "$EXPECTED_TREE" branch --show-current) == "$EXPECTED_BRANCH" ]]
  [[ $(git branch --show-current) == local-feature ]]
  EXPECTED_AGENT=${agent:u}
  wt "$EXPECTED_BRANCH" "$EXPECTED_AGENT"
done
# Git can register a worktree under any name. Preserve its local edits on open.
export EXPECTED_TREE="$scratch/agent workspace" EXPECTED_BRANCH=feature/agent EXPECTED_AGENT=codex
git worktree add -qb "$EXPECTED_BRANCH" "$EXPECTED_TREE" HEAD
print 'first version' > "$EXPECTED_TREE/file"
git -C "$EXPECTED_TREE" add file
git -C "$EXPECTED_TREE" -c user.name=Test -c user.email=test@example.org commit -qm agent
agent_tip=$(git -C "$EXPECTED_TREE" rev-parse HEAD)
print 'unfinished' > "$EXPECTED_TREE/file"
wt "$EXPECTED_BRANCH" codex
[[ $(<"$EXPECTED_TREE/file") == unfinished && ! -e "$scratch/wt-feature-agent" ]]
if dwt feature/agent; then exit 1; fi
git -C "$EXPECTED_TREE" restore file
touch "$EXPECTED_TREE/untracked"
if dwt feature/agent; then exit 1; fi
rm "$EXPECTED_TREE/untracked"
git worktree lock "$EXPECTED_TREE"
cd "$EXPECTED_TREE"
if dwt; then exit 1; fi
[[ $PWD == "$EXPECTED_TREE" ]]
git worktree unlock "$EXPECTED_TREE"
mkdir nested
cd nested
dwt
[[ ! -e "$EXPECTED_TREE" && $PWD == "$scratch/my app" ]]
[[ $(git rev-parse feature/agent) == "$agent_tip" ]]

# Restore a local-only branch, and a remote-only branch with its own upstream.
EXPECTED_TREE="$scratch/wt-feature-agent"
wt feature/agent codex
[[ $(git -C "$EXPECTED_TREE" rev-parse HEAD) == "$agent_tip" ]]
git -C "$scratch/upstream" branch remote-only HEAD~1
export EXPECTED_BRANCH=remote-only EXPECTED_TREE="$scratch/wt-remote-only"
wt remote-only codex
[[ $(git -C "$EXPECTED_TREE" rev-parse HEAD) == $(git -C "$scratch/upstream" rev-parse remote-only) ]]
[[ $(git -C "$EXPECTED_TREE" rev-parse --abbrev-ref '@{u}') == origin/remote-only ]]
cd src
dwt remote-only
[[ ! -e "$EXPECTED_TREE" && $PWD == "$scratch/my app/src" ]]
if dwt remote-only; then exit 1; fi
[[ $(dwt) == *feature/agent* ]]

git worktree add -q "$scratch/default checkout" trunk
git worktree add -qb main "$scratch/main-test" HEAD
mkdir "$scratch/wt-taken"
for args in 'invalid other' 'invalid Claude' 'invalid Codex' 'taken codex' 'bad..name codex'; do
  if wt ${=args}; then exit 1; fi
done
[[ ! -e "$scratch/wt-invalid" ]]
for protected in main trunk local-feature; do
  if wt "$protected" codex; then exit 1; fi
  if dwt "$protected"; then exit 1; fi
done
git worktree add -qd "$scratch/detached" HEAD
(cd "$scratch/detached"; if dwt; then exit 1; fi)
[[ -d "$scratch/detached" ]]
export EXPECTED_BRANCH=retry EXPECTED_TREE="$scratch/wt-retry" FAIL_LAUNCH=1
if wt retry codex; then exit 1; fi
[[ $(git -C "$EXPECTED_TREE" branch --show-current) == retry ]]
unset FAIL_LAUNCH
wt retry codex
git remote set-url origin "$scratch/missing"
if wt offline codex; then exit 1; fi
[[ ! -e "$scratch/wt-offline" ]]
print 'Worktree checks passed.'
