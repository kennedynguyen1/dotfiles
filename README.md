# macOS dotfiles

A terminal setup for working on one Git branch per cmux workspace, with Neovim in one pane and Claude Code or Codex in the other.

## Install

On a Mac with Git and [Homebrew](https://brew.sh), run:

```sh
git clone https://github.com/kennedynguyen1/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup
```

Open a fresh Zsh shell. Keep the clone in place because your shell and terminal configs link to it. Setup preserves existing Neovim configs and stops if a file it needs to link conflicts with yours.

## Work on a branch

Install your preferred agent CLI separately. In cmux, open a shell in your project and run:

```sh
wt fix/login claude
```

This opens Neovim and Claude Code side by side. If the branch already has a checkout, `wt` reuses it wherever it lives. Otherwise it creates `../wt-fix-login`. New branches start at the latest commit on the default branch of `origin`.

| Command | What it does |
| --- | --- |
| `wt fix/login codex` | Open the same branch in a fresh workspace with Codex. |
| `git worktree list` | List checked-out branches and their folders. |
| `dwt fix/login` | Remove the clean checkout and keep the branch. |
| `dwt` | Remove the current task checkout, or list checkouts if you’re in the primary one. |

Use lowercase agent names for normal permissions. Uppercase `CLAUDE` and `CODEX` bypass approval prompts. `CODEX` also disables sandboxing.

Before cleanup, save your edits and stop the agent. An ignored file such as `.env` is deleted along with its worktree, so keep a copy of anything you need.

## Customize

| File | Controls |
| --- | --- |
| [ghostty/config](ghostty/config) | Font, colors, and opacity in Ghostty and cmux |
| [zsh/p10k.zsh](zsh/p10k.zsh) | Powerlevel10k prompt |
| [zsh/personal.zsh](zsh/personal.zsh) | Shell plugins and the `wt` / `dwt` commands |
| [Brewfile](Brewfile) | Apps, fonts, and command-line tools installed by Homebrew |
| [setup](setup) | Config links and the [Kickstart](https://github.com/nvim-lua/kickstart.nvim) revision used for a fresh Neovim install |

To update, run `git pull --ff-only` in the clone. Rerun `./setup` if packages or config links change.
