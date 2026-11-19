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
        "claude": "claude --dangerously-skip-permissions",
        "codex": "codex --dangerously-bypass-approvals-and-sandbox",
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
  export EXPECTED_AGENT=$agent EXPECTED_BRANCH="fix/$agent" EXPECTED_TREE="$scratch/my app-fix-$agent"
  wt "$EXPECTED_BRANCH" "$agent"
  [[ $(git -C "$EXPECTED_TREE" rev-parse HEAD) == "$latest" ]]
  [[ $(git -C "$EXPECTED_TREE" branch --show-current) == "$EXPECTED_BRANCH" ]]
  [[ $(git branch --show-current) == local-feature ]]
  if wt "$EXPECTED_BRANCH" "$agent"; then exit 1; fi
done
mkdir "$scratch/my app-taken"
git -C "$scratch/upstream" branch remote-only
for args in 'invalid other' 'taken codex' 'remote-only claude' 'bad..name codex'; do
  if wt ${=args}; then exit 1; fi
done
export EXPECTED_BRANCH=retry EXPECTED_TREE="$scratch/my app-retry" FAIL_LAUNCH=1
if wt retry codex; then exit 1; fi
[[ $(git -C "$EXPECTED_TREE" branch --show-current) == retry ]]
git remote set-url origin "$scratch/missing"
if wt offline codex; then exit 1; fi
[[ ! -e "$scratch/my app-offline" ]]
print 'Worktree checks passed.'
