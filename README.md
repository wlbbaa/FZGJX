# **贡献&许可**

此脚本为开源脚本，可自由使用和修改，但请保留作者信息：

作者：wlbbaa

GitHub：https://github.com/wlbbaa

Telegram：https://t.me/robberer

Telegram: @robberer

## **辅助工具箱过验证脚本**  

### **简介**  
本脚本用于从 Telegram 获取群组头像，并将其同步到不同版本的 Telegram 缓存目录（如官网版、Google Play 版等）。适用于具有 **Root 权限** 的 **Android 设备**，并需要在 **MT 管理器扩展包环境** 下运行。  

---

### **功能**  
 根据输入的 **群组链接/用户名/群组 ID** 获取 Telegram 群组信息（名称、介绍、ID）。  
 通过 **Telegram Bot API** 获取群组头像（缩略图和完整头像）。  
 **同步头像** 到指定的 Telegram 缓存目录，并进行 **MD5 匹配**，避免重复存储。  
 **自动锁定** 头像文件，防止 Telegram 客户端自动删除。  
 **手动解锁** 选项，允许用户取消文件保护。  

---

### **运行环境**  
- **Root 权限**（必需）  
- **MT 管理器扩展包**（用于命令检测）  
- **Telegram Bot API Token**（需手动配置）  
- **Android 终端**（支持 Bash）  
- **网络要求**：  
  - 需要能够访问 **Telegram API**（`api.telegram.org`）  
  - 如果无法访问 Telegram API，下载会失败，请确保网络可连接 Telegram。  

---

### **使用方法**  

#### **1. 确保设备已 Root，并安装 MT 管理器扩展包**  

---

#### **2. 创建一个 Telegram 机器人，获取 Bot Token**  
- 在 Telegram 搜索 **@BotFather** 并创建一个新 Bot。  
- 记录 **Bot Token**，并填入脚本变量 `BOT_TOKEN` 处。  
- 设置 `CACHE_DIR` 为当前使用的 Telegram 版本的群组头像缓存目录。  

---

#### **3. 赋予脚本可执行权限**  
```sh
chmod +x 过验证.sh
```

---

#### **4. 运行脚本：**
```sh
./过验证.sh
```

---

#### **5. 输入群组链接/用户名/群组 ID：**

例如：

https://t.me/xuehuachat

@xuehuachat

xuehuachat

-1001356996855

---

#### **6. 等待脚本运行，脚本会自动：**

获取群组信息

下载并同步头像

进行文件锁定（防止被 辅助 删除）

---

#### **7. 如果需要取消文件锁定，脚本最后会询问：**

是否取消过验证（取消锁定权限）？**输入 1（不取消，默认）或 2（取消）**：

输入 1 保持锁定（推荐）。

输入 2 解除锁定（仅在需要修改或删除时使用）。

---
