# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time
# 补全菜单可以用方向键选择
zstyle ':completion:*' menu select
# 补全时区分大小写或忽略大小写
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git z zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# >>> Configuration migrated from .bashrc >>>

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Source existing bash config files if they exist
[ -f ~/.bash_aliases ] && . ~/.bash_aliases
[ -f ~/.bash_functions ] && . ~/.bash_functions
[ -f ~/.bash_proxy ] && . ~/.bash_proxy

DOTFILE_LOCAL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/dotfile/local.sh"
[[ -f "$DOTFILE_LOCAL_CONFIG" ]] && source "$DOTFILE_LOCAL_CONFIG"

cuda_home="${DOTFILE_CUDA_HOME:-}"
if [[ -z "$cuda_home" ]]; then
    if [[ -d "$HOME/cuda-12.6" ]]; then
        cuda_home="$HOME/cuda-12.6"
    elif [[ -d "$HOME/cuda-12.1" ]]; then
        cuda_home="$HOME/cuda-12.1"
    fi
fi
if [[ -n "$cuda_home" && -d "$cuda_home" ]]; then
    export CUDA_HOME="$cuda_home"
    export PATH="$PATH:$cuda_home/bin"
    export LD_LIBRARY_PATH="$cuda_home/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

conda_root="${DOTFILE_CONDA_ROOT:-}"
if [[ -z "$conda_root" ]]; then
    for candidate in /data4/lhy/anaconda /data3/lhy/anaconda; do
        if [[ -d "$candidate" ]]; then
            conda_root="$candidate"
            break
        fi
    done
fi

if [[ -n "$conda_root" && -d "$conda_root" ]]; then
    # >>> conda initialize >>>
    __conda_setup="$("$conda_root/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "$conda_root/etc/profile.d/conda.sh" ]; then
            . "$conda_root/etc/profile.d/conda.sh"
        elif [ -d "$conda_root/bin" ]; then
            export PATH="$conda_root/bin:$PATH"
        fi
    fi
    unset __conda_setup
fi
# <<< conda initialize <<<

# Auto-activate PyTorch
if command -v conda >/dev/null 2>&1 && conda info --envs 2>/dev/null | grep -q PyTorch; then
    conda activate PyTorch >/dev/null 2>&1 || true
fi

# <<< Configuration migrated from .bashrc <<<

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if [[ ! "$PATH" == *"$HOME/.fzf/bin"* ]]; then
  PATH="$HOME/.fzf/bin:$PATH"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
