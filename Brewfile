brew "neovim"
brew "ripgrep"
brew "tree-sitter-cli"
brew "powerlevel10k"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "zoxide"
cask "font-meslo-lg-nerd-font"

# These apps may already have been installed outside Homebrew.
{ "ghostty" => "Ghostty.app", "cmux" => "cmux.app" }.each do |name, app|
  cask name unless ["/Applications", File.expand_path("~/Applications")].any? { |dir| File.directory?(File.join(dir, app)) }
end
