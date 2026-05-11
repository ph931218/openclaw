#!/bin/bash
# openclaw-sync.sh - 同步 OpenClaw 配置到 Git 仓库并自动脱敏
# 用法: bash openclaw-sync.sh [repo_path]
# 默认仓库路径: ~/personal/pro/openclaw

set -euo pipefail

REPO="${1:-$HOME/personal/pro/openclaw}"
SOURCE="$HOME/.openclaw"
TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S%z)

echo "=== OpenClaw 配置同步 ==="
echo "时间: $TIMESTAMP"
echo "仓库: $REPO"
echo "源目录: $SOURCE"
echo ""

# 检查仓库是否存在
if [ ! -d "$REPO/.git" ]; then
    echo "❌ 错误: $REPO 不是 Git 仓库"
    exit 1
fi

# 1. 复制并脱敏 openclaw.json
echo "📦 同步 openclaw.json ..."
mkdir -p "$REPO/config"
cp "$SOURCE/openclaw.json" "$REPO/config/openclaw.json"
python3 -c "
import json
SENSITIVE = [
    ('models','providers','oneapi','apiKey'),
    ('gateway','auth','token'),
    ('channels','feishu','appSecret'),
    ('channels','qqbot','clientSecret'),
    ('channels','xiaodu','accessToken'),
]
def mask(s, keep=8):
    if isinstance(s, str) and len(s) > keep:
        return s[:keep] + '*' * (len(s) - keep)
    return s
with open('$REPO/config/openclaw.json') as f:
    c = json.load(f)
for p in SENSITIVE:
    try:
        o = c
        for k in p[:-1]: 
            if k not in o:
                break
            o = o[k]
        else:
            if p[-1] in o:
                o[p[-1]] = mask(o[p[-1]])
    except (KeyError, TypeError):
        pass  # Skip if path doesn't exist

# Always update workspace path
if 'agents' in c and 'defaults' in c['agents']:
    c['agents']['defaults']['workspace'] = '~/.openclaw/workspace'

# Update plugin install paths
for n, i in c.get('plugins',{}).get('installs',{}).items():
    i['installPath'] = '~/.openclaw/extensions/' + n.split('/')[-1]

with open('$REPO/config/openclaw.json','w') as f:
    json.dump(c, f, indent=2, ensure_ascii=False)
print('  ✅ 脱敏完成')
"

# 2. 脱敏 .env
echo "📦 同步 .env ..."
if [ -f "$SOURCE/.env" ]; then
    cp "$SOURCE/.env" "$REPO/config/.env"
    # 脱敏 API Key
    python3 -c "
import re
with open('$REPO/config/.env') as f:
    content = f.read()
content = re.sub(r'(OPENAI_API_KEY=)\"[^\"]+\"', r'\1\"sk-<YOUR_API_KEY_HERE>\"', content)
with open('$REPO/config/.env','w') as f:
    f.write(content)
print('  ✅ .env 脱敏完成')
"
fi

# 3. 同步 workspace
echo "📦 同步 workspace ..."
mkdir -p "$REPO/workspace"
rsync -a --delete \
    --exclude='.git/' \
    --exclude='.openclaw/' \
    --exclude='.DS_Store' \
    --exclude='*.pptx' \
    --exclude='*.docx' \
    "$SOURCE/workspace/" "$REPO/workspace/"
echo "  ✅ workspace 同步完成"

# 4. 同步脚本
echo "📦 同步 scripts ..."
mkdir -p "$REPO/scripts"
if [ -f "$SOURCE/workspace/scripts/sync-models.sh" ]; then
    cp "$SOURCE/workspace/scripts/sync-models.sh" "$REPO/scripts/"
    echo "  ✅ 脚本同步完成"
fi

# 5. 更新 sync-state.json
echo "📝 更新同步状态 ..."
python3 -c "
import json, os, time

state = {
    'lastSyncAt': '$TIMESTAMP',
    'files': [
        {
            'path': 'config/openclaw.json',
            'source': '~/.openclaw/openclaw.json',
            'sourceMtime': '$TIMESTAMP',
            'note': '主配置（已脱敏）'
        },
        {
            'path': 'config/.env',
            'source': '~/.openclaw/.env',
            'sourceMtime': '$TIMESTAMP',
            'note': '环境变量（已脱敏）'
        },
        {
            'path': 'workspace/',
            'source': '~/.openclaw/workspace/',
            'sourceMtime': '$TIMESTAMP',
            'note': 'AI 助手工作区'
        },
        {
            'path': 'scripts/sync-models.sh',
            'source': '~/.openclaw/workspace/scripts/sync-models.sh',
            'sourceMtime': '$TIMESTAMP',
            'note': '模型同步脚本'
        }
    ]
}

with open('$REPO/sync-state.json', 'w') as f:
    json.dump(state, f, indent=2, ensure_ascii=False)
print('  ✅ 状态已更新')
"

# 6. Git commit & push
echo ""
echo "🔄 提交到 Git ..."
cd "$REPO"
git add -A

# 检查是否有变更
if git diff --cached --quiet; then
    echo "  ⏭️ 无变更，跳过提交"
else
    CHANGES=$(git diff --cached --stat | tail -1)
    git commit -m "backup: $TIMESTAMP"
    echo "  ✅ 已提交: $CHANGES"
    echo "  🚀 推送中 ..."
    git push
    echo "  ✅ 推送完成"
fi

echo ""
echo "=== 同步完成 ==="
