#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PROGRAMS=(bash git tmux zsh codex env)
BACKUP_DIR="${HOME}/dotfile_bk_$(date -u +"%Y%m%d%H%M%S")"
DEFAULT_FILES_TO_BACKUP=(
    "$HOME/.bash_profile"
    "$HOME/.bashrc"
    "$HOME/.bash_logout"
    "$HOME/.bash_functions"
    "$HOME/.bash_proxy"
    "$HOME/.gitconfig"
    "$HOME/.tmux.conf"
    "$HOME/.profile"
    "$HOME/.zshrc"
    "$HOME/.p10k.zsh"
    "$HOME/.fzf.zsh"
    "$HOME/.fzf.bash"
    "$HOME/.codex/AGENTS.md"
    "$HOME/.codex/config.toml"
)

log() {
    printf '[dotfile] %s\n' "$*"
}

backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        local rel_path backup_target
        rel_path="${target#$HOME}"
        if [ "$rel_path" = "$target" ]; then
            rel_path="/$(basename "$target")"
        fi
        backup_target="${BACKUP_DIR}${rel_path}"
        mkdir -p "$(dirname "$backup_target")"
        log "Backup ${target} -> ${backup_target}"
        mv "$target" "$backup_target"
    fi
}

link_one() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"

    if [ -L "$dest" ]; then
        local existing
        existing="$(readlink "$dest" 2>/dev/null || true)"
        if [ "$existing" = "$src" ]; then
            return
        fi
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        backup_if_exists "$dest"
    fi

    ln -s "$src" "$dest"
}

link_package_tree() {
    local package_dir="$1"
    local package_name
    package_name="$(basename "$package_dir")"

    if [ ! -d "$package_dir" ]; then
        log "Skip missing package: $package_name"
        return
    fi

    while IFS= read -r -d '' src; do
        local rel dest
        rel="${src#"$package_dir"/}"
        dest="$HOME/$rel"
        link_one "$src" "$dest"
    done < <(find "$package_dir" -type f -print0)
}

clone_or_update() {
    local repo_url="$1"
    local dest_dir="$2"

    if [ -d "$dest_dir/.git" ]; then
        log "Updating $(basename "$dest_dir")"
        git -C "$dest_dir" pull --ff-only
    elif [ -d "$dest_dir" ]; then
        log "Skip existing non-git directory: $dest_dir"
    else
        log "Cloning ${repo_url} -> ${dest_dir}"
        git clone "$repo_url" "$dest_dir"
    fi
}

install_fasd() {
    if [ -x "$HOME/bin/fasd" ]; then
        log "fasd already installed, skip"
        return
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    git clone https://github.com/clvv/fasd.git "$tmp_dir"
    (cd "$tmp_dir" && PREFIX="$HOME" make install >/dev/null)
    rm -rf "$tmp_dir"
}

install_diff_so_fancy() {
    if [ -x "$HOME/bin/diff-so-fancy" ]; then
        log "diff-so-fancy already installed, skip"
        return
    fi
    curl -fsSL \
        https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy \
        -o "$HOME/bin/diff-so-fancy"
    chmod +x "$HOME/bin/diff-so-fancy"
}

install_fzf() {
    if [ -x "$HOME/.fzf/bin/fzf" ]; then
        git -C "$HOME/.fzf" pull --ff-only
    else
        git clone https://github.com/junegunn/fzf.git "$HOME/.fzf"
    fi
    yes | "$HOME/.fzf/install" --key-bindings --completion --no-update-rc >/dev/null
}

install_optional_tools() {
    mkdir -p "$HOME/bin"
    install_fasd
    if command -v curl >/dev/null 2>&1; then
        install_diff_so_fancy
    else
        log "curl missing, skip diff-so-fancy"
    fi

    install_fzf

    mkdir -p "$HOME/.tmux/plugins"
    clone_or_update https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

    if command -v zsh >/dev/null 2>&1; then
        mkdir -p "$HOME/.zsh"
        clone_or_update https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
            "$HOME/.zsh/fast-syntax-highlighting"
        clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
    else
        log "zsh not found, skip oh-my-zsh and zsh highlighting"
    fi
}

main() {
    log "Remove leftover .DS_Store files"
    find "$REPO_DIR" -name '.DS_Store' -delete

    mkdir -p "$HOME/.vim/undodir"

    if ! command -v git >/dev/null 2>&1; then
        log "git is required before running this script"
        exit 1
    fi

    programs=("${DEFAULT_PROGRAMS[@]}")
    files_to_backup=("${DEFAULT_FILES_TO_BACKUP[@]}")

    if [ "${DOTFILE_ENABLE_VIMINFO:-0}" = "1" ]; then
        files_to_backup+=("$HOME/.viminfo")
    fi

    mkdir -p "$BACKUP_DIR"
    for item in "${files_to_backup[@]}"; do
        backup_if_exists "$item"
    done

    for program in "${programs[@]}"; do
        log "Link $program"
        link_package_tree "$REPO_DIR/$program"
    done

    if [ "${DOTFILE_ENABLE_VIMINFO:-0}" = "1" ] && [ -f "$REPO_DIR/vim/.viminfo" ]; then
        log "Install ~/.viminfo from repo snapshot"
        cp "$REPO_DIR/vim/.viminfo" "$HOME/.viminfo"
        chmod 600 "$HOME/.viminfo" 2>/dev/null || true
    fi

    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/dotfile"
    if [ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/dotfile/local.sh" ]; then
        if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/dotfile/local.sh.example" ]; then
            cp "${XDG_CONFIG_HOME:-$HOME/.config}/dotfile/local.sh.example" \
                "${XDG_CONFIG_HOME:-$HOME/.config}/dotfile/local.sh"
            log "Created ${XDG_CONFIG_HOME:-$HOME/.config}/dotfile/local.sh (edit paths if needed)"
        fi
    fi

    if [ "${DOTFILE_SKIP_OPTIONAL_TOOLS:-0}" = "1" ]; then
        log "Skip optional tools (DOTFILE_SKIP_OPTIONAL_TOOLS=1)"
    else
        install_optional_tools
    fi

    log "Done. Backups saved under ${BACKUP_DIR}"
}

main "$@"
