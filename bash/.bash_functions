#!/bin/bash

# 定义服务器映射关系
declare -A SERVER_MAP=(
    ["81"]="202.112.113.81"
    ["90"]="202.112.113.90"
    ["126"]="10.77.110.126"
    ["185"]="10.77.110.185"
    ["191"]="10.77.110.191"
    # 可以继续添加更多映射
)

# 默认用户名
SC_DEFAULT_USER="lhy"

# 解析路径函数：将简化的路径转换为完整的路径格式
parse_path() {
    local path="$1"
    
    if [[ "$path" == @*:* ]]; then
        path="${SC_DEFAULT_USER}${path}"
    fi

    # 如果路径包含@符号，则可能是远程路径
    if [[ "$path" == *@*:* ]]; then
        # 使用参数扩展替代 cut，以兼容 zsh 的词法分割行为
        local user_host="${path%%:*}"   # 获取第一个冒号前的部分 (user@host)
        local dir="${path#*:}"          # 获取第一个冒号后的部分 (path)
        
        local user="${user_host%%@*}"   # 获取@前的部分
        local host="${user_host#*@}"    # 获取@后的部分
        
        # 检查主机名是否在映射中
        if [[ -n "${SERVER_MAP[$host]}" ]]; then
            host="${SERVER_MAP[$host]}"
        fi
        
        # 如果用户为空，使用默认用户名
        if [[ -z "$user" || "$user" == "$host" ]]; then
            user="$SC_DEFAULT_USER"
        fi
        
        echo "${user}@${host}:${dir}"
    else
        # 本地路径直接返回
        echo "$path"
    fi
}

# 自定义函数：简化watch -n 1 nvidia-smi命令为gpu
# 兼容性处理：尝试取消别名，防止 Zsh 将其展开导致函数定义语法错误
# 在 Bash 下如果 gpu 不是别名，此命令会失败但被忽略，不会有任何副作用
unalias gpu 2>/dev/null || true
gpu() {
    # ${1:-1} 表示如果未提供参数，默认值为 1
    watch -n "${1:-1}" nvidia-smi
}

alias G=gpu

# 自定义函数：同步文件和目录，支持本地和远程路径
# 用法: tongbu [-L] [源路径] [目标路径] [SSH端口(可选)]
# 示例1: 本地→远程: tongbu /data4/lhy/project lhy@dest:/data2/lhy/project
# 示例2: 远程→远程: tongbu user@source:/path/to/project user@dest:/path/to/project
# 示例3: 指定端口: tongbu /data4/lhy/project lhy@dest:/data2/lhy/project 8122
# 示例4: 同步软链接: tongbu -L /data4/lhy/project lhy@dest:/data2/lhy/project
# 示例5: 使用简化的服务器标识: tongbu /data4/lhy/project 81:/data2/lhy/project
tongbu() {
    local USE_LINK_FLAG=false
    
    # 检查是否有-L标志
    if [ "$1" = "-L" ]; then
        USE_LINK_FLAG=true
        shift  # 移除已处理的-L参数
    fi
    
    # 检查参数数量
    if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
        echo "错误: 需要提供源路径和目标路径，可选提供SSH端口"
        echo "用法: tongbu [-L] [源路径] [目标路径] [SSH端口(可选)]"
        echo "示例1: tongbu /data4/lhy/project lhy@dest:/data2/lhy/project (本地→远程)"
        echo "示例2: tongbu user@source:/path/to/project user@dest:/path/to/project (远程→远程)"
        echo "示例3: tongbu /data4/lhy/project lhy@dest:/data2/lhy/project 8122 (指定端口)"
        echo "示例4: tongbu -L /data4/lhy/project lhy@dest:/data2/lhy/project (同步软链接)"
        echo "示例5: tongbu /data4/lhy/project 81:/data2/lhy/project (使用简化的服务器标识)"
        return 1
    fi

    # 解析源路径和目标路径
    local SOURCE_PATH=$(parse_path "$1")
    local DEST_PATH=$(parse_path "$2")
    local SSH_PORT=${3:-22}  # 默认使用端口22

    local SSH_CMD
    SSH_CMD=$(command -v ssh 2>/dev/null)
    if [ -z "$SSH_CMD" ]; then
        PATH="/usr/bin:/bin:$PATH"
        SSH_CMD=$(command -v ssh 2>/dev/null)
    fi
    if [ -z "$SSH_CMD" ]; then
        echo "错误: 找不到 ssh，请检查 PATH"
        return 1
    fi

    # === 安全修正：移除源路径末尾的斜杠 ===
    # 防止因Tab补全导致路径带斜杠 (e.g. dir/)，从而使 rsync 只同步内容而误删目标目录下的其他文件夹
    if [[ "$SOURCE_PATH" != "/" ]]; then
        SOURCE_PATH="${SOURCE_PATH%/}"
    fi

    # 判断路径类型：是否为远程路径（包含 @ 符号）
    is_remote_path() {
        [[ "$1" == *@*:* ]]
    }

    # 检查路径是否存在或可访问
    check_path() {
        local path=$1
        if is_remote_path "$path"; then
            # 远程路径检查：仅验证 SSH 连接是否成功
            # 使用参数扩展替代 cut，兼容 Zsh 并提高效率
            local user_host="${path%%:*}"
            local dir="${path#*:}"
            
            $SSH_CMD -p $SSH_PORT -o BatchMode=yes -o ConnectTimeout=5 "$user_host" "exit 0" || {
                echo "错误: 无法通过 SSH 连接到 $user_host (端口: $SSH_PORT)"
                return 1
            }
        else
            # 本地路径检查
            if [ -f "$path" ] || [ -d "$path" ]; then
                return 0
            else
                echo "错误: 路径 $path 不存在或不可访问"
                return 1
            fi
        fi
    }

    # 同步文件
    sync_files() {
        local source=$1
        local dest=$2
        local port=$3

        echo "正在同步 $source → $dest (使用端口: $port)..."
        
        # 根据是否使用-L标志构建rsync命令
        local rsync_flags="avzh"
        if [ "$USE_LINK_FLAG" = true ]; then
            rsync_flags="avzhL"
        fi
        
        # 构建rsync命令的基础部分
        local rsync_cmd="rsync -$rsync_flags --delete --progress -e '$SSH_CMD -p $port -o StrictHostKeyChecking=no'"

        if is_remote_path "$source" && is_remote_path "$dest"; then
            # 远程→远程：通过中间服务器中转
            eval "$rsync_cmd '$source' '$dest'"
        elif is_remote_path "$source"; then
            # 远程→本地
            eval "$rsync_cmd '$source' '$dest'"
        elif is_remote_path "$dest"; then
            # 本地→远程
            eval "$rsync_cmd '$source' '$dest'"
        else
            # 本地→本地
            rsync -$rsync_flags --delete --progress "$source" "$dest"
        fi

        if [ $? -eq 0 ]; then
            echo "同步成功！"
        else
            echo "同步失败，请检查网络或权限设置。"
            return 1
        fi
    }

    # 主流程
    check_path "$SOURCE_PATH" || return 1
    check_path "$DEST_PATH" || return 1
    sync_files "$SOURCE_PATH" "$DEST_PATH" "$SSH_PORT"
}

alias tb=tongbu

# 自定义函数：将文件或文件夹同步到多个目标路径
# 用法: scatter [-L] 源路径 目标路径1 [端口1] 目标路径2 [端口2] ... 目标路径N [端口N]
# 参数规则: 端口参数紧跟在目标路径之后，通过检查参数中是否包含":"来区分路径和端口
# 示例1: scatter /data4/lhy/project lhy@dest1:/data2/lhy/project lhy@dest2:/data3/lhy/project
# 示例2: scatter -L /data4/lhy/project lhy@dest1:/data2/lhy/project 2222 lhy@dest2:/data3/lhy/project 2223
# 示例3: scatter /data4/lhy/project 81:/data2/lhy/project 90:/data3/lhy/project (使用简化的服务器标识)
scatter() {
    local USE_LINK_FLAG=false
    
    # 检查是否有-L标志
    if [ "$1" = "-L" ]; then
        USE_LINK_FLAG=true
        shift  # 移除已处理的-L参数
    fi
    
    # 检查参数数量
    if [ "$#" -lt 2 ]; then
        echo "错误: 需要至少提供一个源路径和一个目标路径"
        echo "用法: scatter [-L] 源路径 目标路径1 [端口1] 目标路径2 [端口2] ... 目标路径N [端口N]"
        echo "参数规则: 端口参数紧跟在目标路径之后，通过检查参数中是否包含\":\"来区分路径和端口"
        echo "示例1: scatter /data4/lhy/project lhy@dest1:/data2/lhy/project lhy@dest2:/data3/lhy/project"
        echo "示例2: scatter -L /data4/lhy/project lhy@dest1:/data2/lhy/project 2222 lhy@dest2:/data3/lhy/project 2223"
        echo "示例3: scatter /data4/lhy/project 81:/data2/lhy/project 90:/data3/lhy/project (使用简化的服务器标识)"
        return 1
    fi

    # 解析源路径
    local SOURCE_PATH=$(parse_path "$1")
    shift  # 移除源路径参数

    echo "开始将 $SOURCE_PATH 同步到目标路径..."
    
    # 处理目标路径和端口参数
    local success_count=0
    local fail_count=0
    local i=1
    
    while [ $i -le $# ]; do
        # 获取目标路径并解析
        eval "local RAW_DEST_PATH=\${$i}"
        local DEST_PATH=$(parse_path "$RAW_DEST_PATH")
        i=$((i + 1))
        
        # 检查下一个参数是否为端口
        local PORT=""
        if [ $i -le $# ]; then
            eval "local NEXT_PARAM=\${$i}"
            # 检查参数中是否包含":"，如果没有则认为是端口
            if [[ "$NEXT_PARAM" != *:* ]]; then
                PORT=$NEXT_PARAM
                i=$((i + 1))  # 跳过端口参数
            fi
        fi
        
        echo "----------------------------------------"
        echo "正在同步到目标: $DEST_PATH${PORT:+ (端口: $PORT)}"
        
        # 调用tongbu函数进行同步
        if [ "$USE_LINK_FLAG" = true ]; then
            if [ -n "$PORT" ]; then
                tongbu -L "$SOURCE_PATH" "$DEST_PATH" "$PORT"
            else
                tongbu -L "$SOURCE_PATH" "$DEST_PATH"
            fi
        else
            if [ -n "$PORT" ]; then
                tongbu "$SOURCE_PATH" "$DEST_PATH" "$PORT"
            else
                tongbu "$SOURCE_PATH" "$DEST_PATH"
            fi
        fi
        
        if [ $? -eq 0 ]; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    echo "========================================"
    echo "同步完成: $success_count 个成功, $fail_count 个失败"
    
    if [ $fail_count -gt 0 ]; then
        return 1
    fi
}

# 为scatter命令创建别名
alias sc=scatter

# 自定义函数：简化tensorboard命令
# 用法: tt [日志路径] [端口号]
# 功能: 自动查找指定路径下的最新tensorboard文件夹并启动tensorboard
# 示例: tt ./log/log_9_3 10006
tsbd() {
    # 检查参数数量
    if [ "$#" -lt 1 ]; then
        echo "错误: 至少需要提供日志路径"
        echo "用法: tt [日志路径] [端口号(可选，默认10006)]"
        echo "示例: tt ./log/log_9_3 10006"
        return 1
    fi

    local LOG_PATH=$1
    local PORT=${2:-10006}  # 默认端口10006

    # 检查日志路径是否存在
    if [ ! -d "$LOG_PATH" ]; then
        echo "错误: 日志路径 $LOG_PATH 不存在"
        return 1
    fi

    # 查找最新的tensorboard文件夹
    local TB_DIR=$(find "$LOG_PATH" -name "tensorboard" -type d | head -n 1)
    
    # 如果没有找到tensorboard文件夹，尝试查找包含名称中包含tensorboard子串的文件夹
    if [ -z "$TB_DIR" ]; then
        TB_DIR=$(find "$LOG_PATH" -name "*tensorboard*" -type d | head -n 1)
    fi
    
    # 如果仍然没有找到，使用日志路径本身
    if [ -z "$TB_DIR" ]; then
        TB_DIR="$LOG_PATH"
        echo "警告: 未找到tensorboard文件夹，将使用日志路径本身: $TB_DIR"
    else
        echo "找到tensorboard目录: $TB_DIR"
    fi

    # 执行tensorboard命令
    echo "启动tensorboard: --logdir=$TB_DIR --port=$PORT --bind_all"
    tensorboard --logdir="$TB_DIR" --port=$PORT --bind_all
}