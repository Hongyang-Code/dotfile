# dotfile

## 中文版

这是一个用于管理个人配置文件的仓库（dotfiles），从 `/home/lhy` 提取。仓库里的文件是后续维护的“源文件”；在新服务器上只需要 clone 本仓库并执行 `./install.sh`，脚本会用 `ln -s` 在 `$HOME` 下创建软链接，并可选安装一些常用工具。

机器相关路径（例如 conda/cuda/zsh 的实际安装位置）不建议写死在 `.bashrc`/`.zshrc` 里。本仓库使用 `~/.config/dotfile/local.sh` 统一配置（首次运行会从 `env/.config/dotfile/local.sh.example` 自动生成）。示例：

```sh
export DOTFILE_CONDA_ROOT="/data4/lhy/anaconda"
export DOTFILE_CUDA_HOME="$HOME/cuda-12.6"
export DOTFILE_ZSH_BIN="/usr/bin/zsh"   # 可选
```

### 快速使用

推送到 GitHub（只需一次）：

```bash
cd /home/lhy/dotfile
git init
git add .
git commit -m "feat: bootstrap dotfiles"
git branch -M main
git remote add origin git@github.com:<your-account>/<repo>.git
git push -u origin main
```

新机器部署：

```bash
git clone git@github.com:<your-account>/<repo>.git ~/dotfile
cd ~/dotfile
./install.sh
```

可选开关：

- 离线/不想下载可选工具：`DOTFILE_SKIP_OPTIONAL_TOOLS=1 ./install.sh`
- 同步一个仓库内的 `~/.viminfo` 快照：`DOTFILE_ENABLE_VIMINFO=1 ./install.sh`（注意 `.viminfo` 是历史/状态文件，更新很频繁）

注意事项：

- `bash/.bash_functions`、`bash/.bash_proxy` 里可能包含敏感信息；如果要公开仓库，建议改成模板或使用私有仓库。
- Codex 的 `~/.codex/auth.json` 和 `~/.codex/sessions/` 不会被纳入仓库（已忽略），避免把 token/日志推到 GitHub。

---

## English

Minimal dotfile management project extracted from `/home/lhy`. The files stored here are the canonical versions that should be tracked in Git and synced to GitHub. Once cloned on a new server you only need to run the provided shell script to recreate the symlinks (via `ln -s`) and bootstrap common tools.

> Note on `conda`, `cuda` and other machine specific paths: set them in `~/.config/dotfile/local.sh`. The rc files include existence checks, so hosts without those directories will not error.

## Layout

```
/home/lhy/dotfile
|-- bash/          # .bashrc, helper functions, proxy settings, profile files
|-- codex/         # ~/.codex/AGENTS.md, ~/.codex/config.toml (prompts/config)
|-- env/           # ~/.config/dotfile/local.sh.example (host-specific paths)
|-- git/           # .gitconfig
|-- tmux/          # .tmux.conf
|-- vim/           # optional snapshot of ~/.viminfo
|-- zsh/           # .zshrc, .p10k.zsh, .fzf.zsh
|-- install.sh     # main bootstrap script (bash)
`-- README.md
```

Add new configs by dropping them into the appropriate folder and re-running `./install.sh`.

## Push to GitHub (run once)

```bash
cd /home/lhy/dotfile
git init
git add .
git commit -m "feat: bootstrap dotfiles"
git branch -M main
git remote add origin git@github.com:<your-account>/<repo>.git
git push -u origin main
```

## Deploy on another machine

```bash
git clone git@github.com:<your-account>/<repo>.git ~/dotfile
cd ~/dotfile
./install.sh
```

After symlinks are created set machine-specific paths in `~/.config/dotfile/local.sh` (auto-created from `local.sh.example` on first run). Proxy settings and server specific secrets live inside `bash/.bash_functions` and `bash/.bash_proxy`, so switch to a private repository or replace them with templates before publishing if needed.

Optional: if you want to also install a tracked snapshot of `~/.viminfo`, run:

```bash
DOTFILE_ENABLE_VIMINFO=1 ./install.sh
```

Note: `.viminfo` is history/state (not really config) and changes frequently.

## What install.sh does

1. Remove `.DS_Store` files under the repo.
2. Backup every pre-existing RC file (`~/.bashrc`, `~/.zshrc`, `~/.gitconfig`, etc.) into `~/dotfile_bk_<timestamp>/`.
3. Ensure `~/.vim/undodir` exists.
4. Create symlinks via `ln -s` for packages under this repo (`bash`, `git`, `tmux`, `zsh`, `codex`, `env`).
5. Install/update helper tools inspired by the sample scripts: `fasd`, `diff-so-fancy`, `fzf`, tmux plugin manager, `oh-my-zsh`, `fast-syntax-highlighting`.

Requirements: `git`, `make`, `curl`, `yes`. Linking is done via `ln -s`.

If you want to skip optional downloads (offline servers), run:

```bash
DOTFILE_SKIP_OPTIONAL_TOOLS=1 ./install.sh
```

## Maintenance tips

- Modify files in this repo and re-run `./install.sh` to refresh symlinks.
- Keep machine specific overrides in `~/.config/dotfile/local.sh`.
- Run `git status` before every commit to ensure no accidental secrets are staged.

## FAQ

**conda/cuda paths on another host** - set `DOTFILE_CONDA_ROOT` / `DOTFILE_CUDA_HOME` in `~/.config/dotfile/local.sh`.

**bootstrap failed** - check network connectivity and ensure `git`, `curl`, and `make` are present. The log lines emitted by `install.sh` indicate which step caused the failure.
