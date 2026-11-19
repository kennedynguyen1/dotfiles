# macOS terminal dotfiles

My Ghostty, cmux, Neovim, and Zsh setup for working on several Git branches at once. I keep the main checkout open and give each task its own folder. From a project in cmux, `wt fix/login codex` opens a sidebar workspace with Neovim on the left and Codex on the right, both in the checkout for `fix/login`.

## Install

You’ll need macOS, Git, and [Homebrew](https://brew.sh) available in your shell. If you want to maintain your own version, fork it and use your fork’s URL below.

```sh
git clone https://github.com/kennedynguyen1/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup
```

Open a new Zsh terminal when setup finishes. Run `nvim .` inside a project to start editing. Keep the clone in place because your live settings link back to it.

The [Brewfile](Brewfile) installs the terminal apps, Neovim, Meslo Nerd Font, and Zsh tools. On a fresh Mac, the [installer](setup) puts a pinned [Kickstart](https://github.com/nvim-lua/kickstart.nvim) config in a separate Neovim checkout. If you already have a Neovim config, setup keeps it. Personal additions such as Diffview are separate.

**Already have dotfiles?** Setup checks the three link destinations before installing packages. If a file differs or a link points elsewhere, it stops and identifies the conflict. For a differing file, it prints a command you can run to compare it privately. Merge or move the file, then rerun `./setup`. The installer appends a loader to your existing `.zshrc` and skips Ghostty or cmux if the app is already installed.

## Work on a task

Open a **Zsh shell in cmux**, change into the Git project you want to develop, and run one of the following. Install and sign in to your preferred agent CLI separately.

| Command | Result |
| --- | --- |
| `wt fix/login claude` or `wt fix/login codex` | Open a new workspace for that branch using the agent’s normal permissions. |
| `git worktree list` | See which branch is checked out in each folder. |
| `dwt fix/login` | Remove the clean task checkout from anywhere in the same repo. Keep the branch for later. |
| `dwt` | Inside a task checkout, remove it and move the shell to the primary checkout. In the primary checkout, list the worktrees. |

A **worktree** is a folder where Git checks out one branch. If an agent already created one, `wt` finds it by branch name and opens it with your edits intact. Otherwise, it creates a sibling folder such as `../wt-fix-login`. It uses the local branch first, then the branch on `origin`. A brand-new branch starts at the latest commit on the default branch of `origin`. Both helpers protect the primary checkout, `main`, and the default branch of `origin`. When `origin` is configured, they need access to it.

**Agent permissions:** Uppercase `CLAUDE` or `CODEX` bypasses approval prompts. `CODEX` also disables its sandbox. A worktree separates Git checkouts, but the agent can still access other files with your account’s permissions.

**Before cleanup:** Save your buffers and stop the agent. `dwt` refuses locked worktrees and changes reported by Git, including untracked files. Ignored files such as a worktree-only `.env` can be deleted with the folder. Close the cmux workspace yourself when you’re done.

## Customize and update

| To change | Edit in this repo | Linked location |
| --- | --- | --- |
| Terminal font and colors | [ghostty/config](ghostty/config) | `~/.config/ghostty/config` |
| Prompt | [zsh/p10k.zsh](zsh/p10k.zsh) | `~/.p10k.zsh` |
| Autosuggestions, syntax highlighting, zoxide, and the worktree helpers | [zsh/personal.zsh](zsh/personal.zsh) | `~/.config/zsh/personal.zsh` |

The paths above use the default config directory. Setup respects `XDG_CONFIG_HOME` and uses `ZDOTDIR` for the Zsh startup file when set.

To update an existing install, run `git pull --ff-only` in the clone and open a fresh shell. Rerun `./setup` when the Brewfile or linked paths change. To sync your own customizations across Macs, commit them to your fork and pull on the other machine.
