#!/bin/bash
#改东西不留名你忒不地道
#贡献&许可
#此脚本为开源脚本，可自由使用和修改，但请保留作者信息：
#作者：wlbbaa
#GitHub：https://github.com/wlbbaa
#Telegram：https://t.me/robberer

if [ "$(id -u)" -ne 0 ]; then
    echo "请设置以 Root 用户运行"
    exit 1
fi

# 检查是否安装 MT 管理器扩展包 是否可用
if ! command -v ssh-keygen > /dev/null 2>&1; then
    echo -e "${RED}请使用 MT 管理器扩展包环境执行！${RESET}\n"
    exit 1
fi

# 设置变量
BOT_TOKEN="使用你提供的 Bot Token"  # 使用你提供的 Bot Token
CACHE_DIR="/storage/emulated/0/Android/data/com.radolyn.ayugram/cache"  # 你使用的电报版本头像缓存目录
OFFICIAL_CACHE_DIR="/storage/emulated/0/Android/data/org.telegram.messenger.web/cache"  # 官网版本电报头像缓存目录
GOOGLE_CACHE_DIR="/storage/emulated/0/Android/data/org.telegram.messenger/cache"  # Google 版本电报头像缓存目录

# 创建缓存目录（如果不存在）
[ ! -d "$OFFICIAL_CACHE_DIR" ] && mkdir -p "$OFFICIAL_CACHE_DIR"
[ ! -d "$GOOGLE_CACHE_DIR" ] && mkdir -p "$GOOGLE_CACHE_DIR"

# 提示用户输入群组链接、用户名或群组 ID
echo "请输入 Telegram 群组的链接、用户名或群组 ID（例如 https://t.me/xuehuachat、@xuehuachat、xuehuachat 或 -1002498101566）："
read INPUT

# 检查输入是否为空
if [ -z "$INPUT" ]; then
    echo "错误：输入不能为空！"
    exit 1
fi

# 处理输入，提取或构造群组标识
if [[ "$INPUT" =~ ^https://t.me/(.+)$ ]]; then
    CHAT_ID="@${BASH_REMATCH[1]}"
elif [[ "$INPUT" =~ ^@.+$ ]]; then
    CHAT_ID="$INPUT"
elif [[ "$INPUT" =~ ^[a-zA-Z0-9_]+$ ]]; then
    CHAT_ID="@$INPUT"
elif [[ "$INPUT" =~ ^-?[0-9]+$ ]]; then
    CHAT_ID="$INPUT"  # 直接使用群组 ID
else
    echo "错误：请输入有效的群组链接（例如 https://t.me/xuehuachat）、用户名（例如 @xuehuachat）、简写（例如 xuehuachat）或群组 ID（例如 -1001356996855）！"
    exit 1
fi

# Telegram API 请求 URL
API_URL="https://api.telegram.org/bot${BOT_TOKEN}/getChat?chat_id=${CHAT_ID}"

# 使用 curl 发送请求并保存响应
response=$(curl -s "$API_URL")

# 函数：将 Unicode 转义字符转换为中文
decode_unicode() {
    local input="$1"
    if [[ ! "$input" =~ \\[ux] ]]; then
        echo "$input"
        return
    fi
    printf '%b' "$(echo "$input" | sed 's/\\u\(....\)/\\u\1/g;s/\\x{\(....\)}/\\u\1/g')"
}

# 检查 MD5 的函数
check_md5_match() {
    local file1="$1"
    local file2="$2"
    if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
        return 1
    fi
    md5_1=$(md5sum "$file1" | cut -d' ' -f1)
    md5_2=$(md5sum "$file2" | cut -d' ' -f1)
    [ "$md5_1" = "$md5_2" ]
}

# 检查请求是否成功
if echo "$response" | grep -q '"ok":true'; then
    # 提取群名并解码
    group_name=$(echo "$response" | sed -n 's/.*"title":"\{0,1\}\([^"]*\)"\{0,1\},.*/\1/p' | sed 's/\\"/"/g')
    group_name=$(decode_unicode "$group_name")
    # 提取群组介绍并解码
    group_description=$(echo "$response" | sed -n 's/.*"description":"\{0,1\}\([^"]*\)"\{0,1\},.*/\1/p' | sed 's/\\"/"/g')
    [ -z "$group_description" ] && group_description="无描述" || group_description=$(decode_unicode "$group_description")
    # 提取群组 ID、缩略图文件 ID 和完整图文件 ID
    chat_id=$(echo "$response" | sed -n 's/.*"id":\([-0-9]*\),.*/\1/p')
    small_photo_id=$(echo "$response" | sed -n 's/.*"small_file_id":"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p')
    big_photo_id=$(echo "$response" | sed -n 's/.*"big_file_id":"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p')

    # 输出基本信息
    echo "群名: $group_name"
    echo "群组介绍: $group_description"
    echo "群组 ID: $chat_id"

    # 处理缩略图
    if [ -n "$small_photo_id" ]; then
        echo "缩略图文件 ID: $small_photo_id"
        # 下载缩略图到当前目录
        file_response=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getFile?file_id=${small_photo_id}")
        file_path=$(echo "$file_response" | sed -n 's/.*"file_path":"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p')
        if [ -n "$file_path" ]; then
            curl -s "https://api.telegram.org/file/bot${BOT_TOKEN}/${file_path}" -o "temp_thumbnail.jpg"
            if [ ! -f "temp_thumbnail.jpg" ]; then
                echo "错误：缩略图下载失败，请检查网络"
            else
                # 检查缓存目录中的缩略图
                thumbnail_found=false
                if [ -d "$CACHE_DIR" ] && [ -r "$CACHE_DIR" ]; then
                    for cache_file in "$CACHE_DIR"/*_97.jpg; do
                        if [ -f "$cache_file" ] && check_md5_match "temp_thumbnail.jpg" "$cache_file"; then
                            # 从缓存文件名中提取数字部分
                            file_base=$(basename "$cache_file" _97.jpg)
                            thumbnail_found=true
                            break
                        fi
                    done
                fi

                # 根据是否找到缓存，确定文件名
                if [ "$thumbnail_found" = true ]; then
                    thumbnail_name="${file_base}_97.jpg"
                else
                    thumbnail_name="thumbnail_${chat_id}_97.jpg"
                fi

                # 移动到官网版本缓存目录
                if [ -d "$OFFICIAL_CACHE_DIR" ] && [ -w "$OFFICIAL_CACHE_DIR" ]; then
                    chattr -ia "$OFFICIAL_CACHE_DIR/$thumbnail_name" 2>/dev/null  # 解除锁定
                    cp "temp_thumbnail.jpg" "$OFFICIAL_CACHE_DIR/$thumbnail_name" 2>/dev/null || echo "错误：复制缩略图到官网缓存目录失败"
                    chattr +ia "$OFFICIAL_CACHE_DIR/$thumbnail_name" 2>/dev/null  # 锁定文件
                    echo "缩略图已移动并锁定到 $OFFICIAL_CACHE_DIR/$thumbnail_name"
                else
                    echo "无法访问官网缓存目录 $OFFICIAL_CACHE_DIR，请检查权限"
                fi

                # 移动到 Google 版本缓存目录
                if [ -d "$GOOGLE_CACHE_DIR" ] && [ -w "$GOOGLE_CACHE_DIR" ]; then
                    chattr -ia "$GOOGLE_CACHE_DIR/$thumbnail_name" 2>/dev/null  # 解除锁定
                    mv -- "temp_thumbnail.jpg" "$GOOGLE_CACHE_DIR/$thumbnail_name" 2>/dev/null || echo "错误：移动缩略图到 Google 缓存目录失败"
                    chattr +ia "$GOOGLE_CACHE_DIR/$thumbnail_name" 2>/dev/null  # 锁定文件
                    echo "缩略图已移动并锁定到 $GOOGLE_CACHE_DIR/$thumbnail_name"
                else
                    echo "无法访问 Google 缓存目录 $GOOGLE_CACHE_DIR，请检查权限"
                    rm -f "temp_thumbnail.jpg"  # 清理临时文件
                fi
            fi
        else
            echo "无法下载缩略图（可能需要 Bot 加入群组以获取完整权限）"
        fi
    else
        echo "缩略图文件 ID: 无缩略图"
    fi

    # 处理完整头像
    if [ -n "$big_photo_id" ]; then
        echo "完整图文件 ID: $big_photo_id"
        # 下载完整图到当前目录
        file_response=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getFile?file_id=${big_photo_id}")
        file_path=$(echo "$file_response" | sed -n 's/.*"file_path":"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p')
        if [ -n "$file_path" ]; then
            curl -s "https://api.telegram.org/file/bot${BOT_TOKEN}/${file_path}" -o "temp_full.jpg"
            if [ ! -f "temp_full.jpg" ]; then
                echo "错误：完整头像下载失败，请检查网络"
            else
                # 根据缩略图是否匹配缓存，确定完整图文件名
                if [ "$thumbnail_found" = true ]; then
                    full_name="${file_base}_99.jpg"
                else
                    full_name="thumbnail_${chat_id}_99.jpg"
                fi

                # 移动到官网版本缓存目录
                if [ -d "$OFFICIAL_CACHE_DIR" ] && [ -w "$OFFICIAL_CACHE_DIR" ]; then
                    chattr -ia "$OFFICIAL_CACHE_DIR/$full_name" 2>/dev/null  # 解除锁定
                    cp "temp_full.jpg" "$OFFICIAL_CACHE_DIR/$full_name" 2>/dev/null || echo "错误：复制完整头像到官网缓存目录失败"
                    chattr +ia "$OFFICIAL_CACHE_DIR/$full_name" 2>/dev/null  # 锁定文件
                    echo "完整头像已移动并锁定到 $OFFICIAL_CACHE_DIR/$full_name"
                else
                    echo "无法访问官网缓存目录 $OFFICIAL_CACHE_DIR，请检查权限"
                fi

                # 移动到 Google 版本缓存目录
                if [ -d "$GOOGLE_CACHE_DIR" ] && [ -w "$GOOGLE_CACHE_DIR" ]; then
                    chattr -ia "$GOOGLE_CACHE_DIR/$full_name" 2>/dev/null  # 解除锁定
                    mv -- "temp_full.jpg" "$GOOGLE_CACHE_DIR/$full_name" 2>/dev/null || echo "错误：移动完整头像到 Google 缓存目录失败"
                    chattr +ia "$GOOGLE_CACHE_DIR/$full_name" 2>/dev/null  # 锁定文件
                    echo "完整头像已移动并锁定到 $GOOGLE_CACHE_DIR/$full_name"
                else
                    echo "无法访问 Google 缓存目录 $GOOGLE_CACHE_DIR，请检查权限"
                    rm -f "temp_full.jpg"  # 清理临时文件
                fi
            fi
        else
            echo "无法下载完整头像（可能需要 Bot 加入群组以获取完整权限）"
        fi
    else
        echo "完整图文件 ID: 无完整图"
    fi

    # 询问是否取消过验证（锁定权限）
    echo "是否取消过验证（取消锁定权限）？输入 1（不取消，默认）或 2（取消）："
    read choice

    # 如果未输入（直接回车）或输入 1，则不取消
    if [ -z "$choice" ] || [ "$choice" = "1" ]; then
        echo "锁定权限未取消"
    # 如果输入 2，则取消锁定权限
    elif [ "$choice" = "2" ]; then
        # 取消 OFFICIAL_CACHE_DIR 下所有文件的锁定
        if [ -d "$OFFICIAL_CACHE_DIR" ]; then
            for file in "$OFFICIAL_CACHE_DIR"/*; do
                [ -f "$file" ] && chattr -ia "$file" 2>/dev/null
            done
        fi
        # 取消 GOOGLE_CACHE_DIR 下所有文件的锁定
        if [ -d "$GOOGLE_CACHE_DIR" ]; then
            for file in "$GOOGLE_CACHE_DIR"/*; do
                [ -f "$file" ] && chattr -ia "$file" 2>/dev/null
            done
        fi
        echo "已取消"
    else
        echo "无效输入，默认不取消锁定权限"
    fi
else
    error_msg=$(echo "$response" | sed -n 's/.*"description":"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p')
    [ -z "$error_msg" ] && error_msg="未知错误（API 响应: $response）"
    echo "请求失败: $error_msg"
    echo "提示：请确保输入的是有效的群组链接、用户名或群组 ID，并检查网络连接。"
fi