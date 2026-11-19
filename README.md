# macOS dotfiles

Keep your terminal settings in Git and use them across Macs. Run `./setup` on each Mac to install the tools and link Ghostty, Zsh, and Neovim to this repo. Edit a setting once, then commit, push, and pull to use it on another Mac.

## Set up a Mac

Install Git and [Homebrew](https://brew.sh), then run the following commands. To sync your own changes, fork this repo first and use your fork’s URL.

```sh
git clone https://github.com/kennedynguyen1/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup
```

Open a fresh Zsh shell. Keep the clone in place because the live config paths below are symlinks to files in the clone. If an existing file conflicts, setup stops and shows you where to look.

| Edit in the repo | Live config on your Mac | What it controls |
| --- | --- | --- |
| [ghostty/config](ghostty/config) | `~/.config/ghostty/config` | Font and colors in Ghostty and cmux |
| [nvim/](nvim/) | `~/.config/nvim` | Kickstart, keymaps, Diffview, and plugin versions |
| [zsh/p10k.zsh](zsh/p10k.zsh) | `~/.p10k.zsh` | Powerlevel10k prompt |
| [zsh/personal.zsh](zsh/personal.zsh) | `~/.config/zsh/personal.zsh` | Shell plugins and worktree commands |

The [Brewfile](Brewfile) lists the apps, fonts, and CLI tools. The [Neovim config](nvim/init.lua) is based on [Kickstart](https://github.com/nvim-lua/kickstart.nvim) and includes Diffview (`Space d o` to open, `Space d c` to close). On first launch, allow Neovim to install the plugins listed in its [lockfile](nvim/nvim-pack-lock.json).

**Already have a Neovim config?** Setup stops if the config directory exists separately. Move it to an unused backup path, rerun `./setup`, and merge any settings you want to keep. For example, if `~/.config/nvim.backup` is unused, run `mv ~/.config/nvim ~/.config/nvim.backup`. Use your config directory instead if you set `XDG_CONFIG_HOME`.

## Sync a change

For example, edit the font size in `~/dotfiles/ghostty/config`. On the Mac where you made the change, run:

```sh
cd ~/dotfiles
git diff
git add ghostty/config
git commit -m "Adjust terminal font size"
git push
```

On your other Mac, run `git -C ~/dotfiles pull --ff-only`. The linked files update immediately. Reload your terminal config to see appearance changes, or open a fresh shell for Zsh changes. Restart Neovim for editor changes. Rerun `./setup` when packages or config links change.

## Optional cmux worktree commands

Install your preferred agent CLI separately. In cmux, open a shell in your project and run:

```sh
cwt fix/login claude
```

This opens Neovim and Claude Code side by side. If the branch already has a checkout, `cwt` reuses it wherever it lives. Otherwise it creates `../wt-fix-login`. New branches start at the latest commit on the default branch of `origin`.

| Command | What it does |
| --- | --- |
| `cwt fix/login codex` | Open the same branch in a fresh workspace with Codex. |
| `git worktree list` | List checked-out branches and their folders. |
| `dwt fix/login` | Remove the clean checkout and keep the branch. |
| `dwt` | Remove the current task checkout, or list checkouts if you’re in the primary one. |

Use lowercase agent names for normal permissions. Uppercase `CLAUDE` and `CODEX` bypass approval prompts. `CODEX` also disables sandboxing.

Before cleanup, save your edits and stop the agent. An ignored file such as `.env` is deleted along with its worktree, so keep a copy of anything you need.
