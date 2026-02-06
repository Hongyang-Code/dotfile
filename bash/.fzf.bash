#!/usr/bin/env bash
# fzf shell integration for bash (portable: uses $HOME)

if [[ ":$PATH:" != *":$HOME/.fzf/bin:"* ]]; then
  PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

[[ -f "$HOME/.fzf/shell/completion.bash" ]] && source "$HOME/.fzf/shell/completion.bash"
[[ -f "$HOME/.fzf/shell/key-bindings.bash" ]] && source "$HOME/.fzf/shell/key-bindings.bash"

