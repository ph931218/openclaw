# OpenClaw 配置备份

> 将 OpenClaw 从一台电脑迁移到另一台电脑的完整指南。
>
> **所有敏感信息已脱敏**，恢复时需要手动填回。

---

## 目录结构

```
openclaw/
├── README.md                    # 本文件
├── config/
│   ├── openclaw.json            # 主配置（已脱敏）
│   ├── .env                     # 环境变量（已脱敏）
│   └── device.json.example      # 设备密钥示例（无需手动配置）
├── workspace/                   # AI 助手的工作区（核心"记忆"）
│   ├── AGENTS.md                # 助手行为准则
│   ├── SOUL.md                  # 助手人格设定
│   ├── IDENTITY.md              # 助手身份信息
│   ├── USER.md                  # 用户信息
│   ├── MEMORY.md                # 长期记忆
│   ├── HEARTBEAT.md             # 心跳任务配置
│   ├── TOOLS.md                 # 工具备注
│   ├── memory/                  # 每日记忆 & 状态文件
│   └── scripts/
│       └── sync-models.sh       # OneAPI 模型同步脚本
├── memory/                      # 状态文件备份
│   ├── ai-news-state.json
│   ├── frontend-tech-state.json
│   └── sync-models-state.json
└── scripts/
    └── sync-models.sh
```

---

## 恢复步骤

### 1. 安装 OpenClaw

```bash
# macOS (Homebrew)
brew install openclaw

# 或通过 npm
npm install -g openclaw
```

### 2. 初始化 OpenClaw

```bash
openclaw init
```

按照向导完成基础配置（大部分内容后面会被我们的配置覆盖）。

### 3. 覆盖配置文件

#### 3.1 主配置 `openclaw.json`

将 `config/openclaw.json` 复制到 `~/.openclaw/openclaw.json`，然后**手动修改以下脱敏字段**：

| 字段路径 | 说明 | 如何获取 |
|---------|------|---------|
| `models.providers.oneapi.apiKey` | OneAPI 密钥 | OneAPI 管理后台获取 |
| `gateway.auth.token` | 网关认证 Token | 运行 `openclaw gateway start` 自动生成，或手动设置 |
| `channels.feishu.appId` | 飞书应用 App ID | [飞书开放平台](https://open.feishu.cn/) → 你的应用 → 凭证 |
| `channels.feishu.appSecret` | 飞书应用 App Secret | 同上 |
| `channels.feishu.allowFrom[0]` | 飞书允许的用户 open_id | 你自己的飞书 open_id |
| `channels.qqbot.appId` | QQ 频道机器人 App ID | [QQ 开放平台](https://q.qq.com/) → 机器人管理 |
| `channels.qqbot.clientSecret` | QQ 频道机器人 Client Secret | 同上 |
| `channels.xiaodu.accessToken` | 小度技能 Access Token | [DuerOS 技能平台](https://dueros.baidu.com/) |

**快速定位脱敏字段**（搜索 `****`）：

```bash
grep -n '\*\*\*\*' ~/.openclaw/openclaw.json
```

#### 3.2 环境变量 `.env`

将 `config/.env` 复制到 `~/.openclaw/.env`，填入真实的 API Key：

```bash
OPENAI_API_KEY="sk-你的真实密钥"
OPENAI_API_BASE="https://oneapi-comate.baidu-int.com/v1"
```

#### 3.3 工作区 `workspace/`

将整个 `workspace/` 目录复制到 `~/.openclaw/workspace/`：

```bash
cp -r workspace/* ~/.openclaw/workspace/
cp -r workspace/.* ~/.openclaw/workspace/ 2>/dev/null || true
```

> **这是 AI 助手的"大脑"**，包含所有记忆、人格、行为准则。直接覆盖即可。

#### 3.4 同步脚本

```bash
mkdir -p ~/.openclaw/workspace/scripts
cp scripts/sync-models.sh ~/.openclaw/workspace/scripts/
chmod +x ~/.openclaw/workspace/scripts/sync-models.sh
```

### 4. 安装插件

```bash
# 飞书 (Lark)
openclaw plugin install @larksuite/openclaw-lark@latest

# QQ 频道
openclaw plugin install @tencent-connect/openclaw-qqbot@latest

# 微信
openclaw plugin install @tencent-weixin/openclaw-weixin@latest

# 小度
openclaw plugin install openclaw-xiaodu

# 安全盾
openclaw plugin install openclaw-safeshield
```

安装后需要在 `openclaw.json` 的 `plugins.entries` 中启用对应的插件（配置文件中已包含）。

### 5. 微信额外配置

微信插件需要额外配置账号授权：

1. 复制 `~/.openclaw/openclaw-weixin/` 目录（如已有备份）
2. 或重新扫码绑定微信

### 6. 启动 & 验证

```bash
# 启动网关
openclaw gateway start

# 检查状态
openclaw status

# 查看各通道连接状态
openclaw gateway status
```

---

## 脱敏字段清单

以下是本仓库中已脱敏的字段，恢复时**必须**手动填回：

| 文件 | 字段 | 原始格式 | 脱敏后 |
|-----|------|---------|-------|
| `.env` | `OPENAI_API_KEY` | `sk-xxxxxxxx...` | `sk-<YOUR_API_KEY_HERE>` |
| `openclaw.json` | `models.providers.oneapi.apiKey` | 64位字符串 | 前8位 + `****` |
| `openclaw.json` | `gateway.auth.token` | 48位十六进制 | 前8位 + `****` |
| `openclaw.json` | `channels.feishu.appSecret` | 32位字符串 | 前8位 + `****` |
| `openclaw.json` | `channels.qqbot.clientSecret` | 16位字符串 | 前8位 + `****` |
| `openclaw.json` | `channels.xiaodu.accessToken` | 带前缀的长字符串 | 前8位 + `****` |
| `identity/` | 私钥 & Token | Ed25519 密钥对 | 仅保留结构示例 |

---

## 不需要备份的内容

以下内容由 OpenClaw 自动生成，无需手动迁移：

- `~/.openclaw/identity/` — 设备密钥，`openclaw init` 自动生成
- `~/.openclaw/cron/` — 定时任务，会自动从配置重建
- `~/.openclaw/logs/` — 日志文件
- `~/.openclaw/tasks/` — 任务运行记录
- `~/.openclaw/sessions/` — 会话数据（旧会话不需要迁移）
- `~/.openclaw/completions/` — Shell 补全脚本，随安装自动生成
- `~/.openclaw/exec-approvals.json` — 审批记录

---

## 日常维护建议

### 定期同步到 Git

```bash
# 添加新的变更
cd ~/personal/pro/openclaw
cp ~/.openclaw/openclaw.json config/openclaw.json
# 重新脱敏（运行下方 Python 脚本）
python3 sanitize.py
git add -A && git commit -m "backup: $(date +%Y-%m-%d)" && git push
```

### 脱敏脚本

仓库中可以保存一个 `sanitize.py`，用于自动脱敏 `openclaw.json`：

```python
#!/usr/bin/env python3
"""sanitize.py - 脱敏 openclaw.json 中的敏感字段"""
import json

SENSITIVE_PATHS = [
    ("models", "providers", "oneapi", "apiKey"),
    ("gateway", "auth", "token"),
    ("channels", "feishu", "appSecret"),
    ("channels", "qqbot", "clientSecret"),
    ("channels", "xiaodu", "accessToken"),
]

def mask(s, keep=8):
    if isinstance(s, str) and len(s) > keep:
        return s[:keep] + '*' * (len(s) - keep)
    return s

with open("config/openclaw.json") as f:
    config = json.load(f)

for path in SENSITIVE_PATHS:
    obj = config
    for key in path[:-1]:
        obj = obj[key]
    obj[path[-1]] = mask(obj[path[-1]])

# 通用化路径
config["agents"]["defaults"]["workspace"] = "~/.openclaw/workspace"

with open("config/openclaw.json", "w") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)

print("Done. Sensitive fields masked.")
```

### .gitignore 建议

```gitignore
# 绝对不能提交的真实凭据
*.key
*.pem
*.env.local
openclaw-weixin/accounts/
```

---

## 注意事项

1. **不要将真实密钥提交到公开仓库** — 即使是私有仓库也要注意安全
2. **模型列表会变化** — 新电脑恢复后运行 `bash ~/.openclaw/workspace/scripts/sync-models.sh` 同步最新模型
3. **飞书用户授权需要重新做** — 用户 OAuth Token 不能迁移，需重新授权
4. **微信扫码绑定需要重做** — 微信的 token 绑定设备
