# Mac dotfiles

Ghostty, cmux, Neovim, a Meslo Nerd Font, and a Zsh prompt with Powerlevel10k, autosuggestions, syntax highlighting, and zoxide.

## Set up a Mac

After company onboarding, install [Homebrew](https://brew.sh) if needed and follow its shell instructions so `brew` is on your PATH. With Git and SSH access to this private repo, run:

```sh
git clone git@github.com:kennedynguyen1/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup
```

Keep the clone in a stable location. Setup skips Ghostty and cmux when their app bundles already exist in `/Applications` or `~/Applications`. Homebrew supplies missing dependencies with upgrades disabled.

| Live config | File in this repo |
| --- | --- |
| `~/.p10k.zsh` | `zsh/p10k.zsh` |
| `~/.config/ghostty/config` | `ghostty/config` |
| `~/.config/zsh/personal.zsh` | `zsh/personal.zsh` |

Setup links missing files and converts byte-identical files to symlinks. If a local file differs, setup prints a diff and stops before installing anything. Review and merge the changes, or move the local file aside, then rerun. A link pointing somewhere else also requires review. The paths under `~/.config` follow `XDG_CONFIG_HOME` when set.

Your local `.zshrc` loads the linked shell settings through a single guarded line. Open a new terminal to use the prompt. If you already initialize these plugins yourself, remove their duplicate initialization after reviewing the hook.

A fresh Neovim install gets [Kickstart](https://github.com/nvim-lua/kickstart.nvim) at commit `8e35dbedb7966e3a95e1f26f9fc1179ab6c68db4`. Existing Neovim directories are preserved. Neovim edits live in that separate checkout. cmux currently uses its defaults.

## Start a task in cmux

From a Git repo in cmux, run `wt fix/login claude` or `wt fix/login codex`. Install the selected agent CLI first. The command creates the branch from the latest commit on the default branch of `origin`. For a repo called `myapp`, it opens a sibling checkout named `myapp-fix-login`, with Neovim on the left and the agent on the right. Local-only files such as `.env` stay in the original checkout.

Agents launched by `wt` skip tool approval prompts. Codex also runs without its sandbox. Either agent can affect files outside the worktree with your account's permissions.

## Share a change

Edit a linked file at its usual path, then review and push from the repo. For example:

```sh
cd ~/dotfiles
git diff
git add zsh/p10k.zsh
git commit -m "Adjust prompt layout"
git push
```

On the other Mac, run `git pull --ff-only` in the clone. The linked files reflect the pull immediately. Open a new shell for prompt changes. Rerun `./setup` when the Brewfile or list of links changes.

If an editor replaces a link with a regular file, `./setup` will compare it with the repo copy. Merge the edit and rerun to restore the link.
