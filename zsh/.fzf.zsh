# Setup fzf
# ---------
if [[ ! "$PATH" == *"$HOME/.fzf/bin"* ]]; then
  PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

[ -f "$HOME/.fzf/shell/completion.zsh" ] && source "$HOME/.fzf/shell/completion.zsh"
[ -f "$HOME/.fzf/shell/key-bindings.zsh" ] && source "$HOME/.fzf/shell/key-bindings.zsh"
