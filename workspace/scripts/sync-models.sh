#!/bin/bash
# sync-models.sh - 从 OneAPI 同步模型列表到本地配置
# 安全策略：只增不删，不动其他配置，已有模型属性保留

set -euo pipefail

CONFIG_FILE="$HOME/.openclaw/openclaw.json"
TMP_FILE=$(mktemp)
trap "rm -f $TMP_FILE" EXIT

API_BASE="https://oneapi-comate.baidu-int.com/v1"
API_KEY=$(python3 -c "
import json
c=json.load(open('$CONFIG_FILE'))
print(c['models']['providers']['oneapi']['apiKey'])
")

# 1. 查询 API 模型列表
echo "=== 查询 OneAPI 模型列表 ==="
API_MODELS=$(curl -sf -H "Authorization: Bearer $API_KEY" "$API_BASE/models" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for m in data.get('data', []):
    print(m['id'])
") || { echo "ERROR: API 查询失败"; exit 1; }

API_COUNT=$(echo "$API_MODELS" | wc -l | tr -d ' ')
echo "API 返回 $API_COUNT 个模型"

# 2. 读取本地配置中的模型 ID
LOCAL_MODELS=$(python3 -c "
import json
c=json.load(open('$CONFIG_FILE'))
for m in c['models']['providers']['oneapi']['models']:
    print(m['id'])
")
LOCAL_COUNT=$(echo "$LOCAL_MODELS" | wc -l | tr -d ' ')
echo "本地配置 $LOCAL_COUNT 个模型"

# 3. 找出差异
NEW_MODELS=""
while IFS= read -r model; do
    if ! echo "$LOCAL_MODELS" | grep -qxF "$model"; then
        NEW_MODELS="$NEW_MODELS$model"$'\n'
    fi
done <<< "$API_MODELS"

REMOVED_MODELS=""
while IFS= read -r model; do
    if ! echo "$API_MODELS" | grep -qxF "$model"; then
        REMOVED_MODELS="$REMOVED_MODELS"$'\n'"$model"
    fi
done <<< "$LOCAL_MODELS"

# 4. 输出差异报告
echo ""
echo "=== 差异报告 ==="

if [ -z "$NEW_MODELS" ]; then
    echo "📦 无新增模型"
else
    echo "🆕 新增模型（将自动添加）:"
    echo "$NEW_MODELS" | sed '/^$/d' | while read -r m; do echo "  + $m"; done
fi

if [ -z "$REMOVED_MODELS" ]; then
    echo "🗑️ 无缺失模型"
else
    echo "⚠️ API 上缺失的模型（仅报告，不删除）:"
    echo "$REMOVED_MODELS" | sed '/^$/d' | while read -r m; do echo "  - $m"; done
fi

# 5. 如果有新增，执行安全合并（输出到临时文件，最后校验再替换）
if [ -n "$NEW_MODELS" ]; then
    echo ""
    echo "=== 执行安全合并 ==="

    NEW_MODELS_LIST="$(echo "$NEW_MODELS" | sed '/^$/d')" python3 - "$CONFIG_FILE" > "$TMP_FILE.out" << 'PYEOF'
import json, sys
import os

config_path = sys.argv[1]
with open(config_path) as f:
    config = json.load(f)

models = config['models']['providers']['oneapi']['models']
existing_ids = {m['id'] for m in models}

# 从环境变量读取新模型 ID，避免 stdin 被 heredoc 占用
new_ids = [line for line in os.environ.get('NEW_MODELS_LIST', '').split('\n') if line and line not in existing_ids]

if not new_ids:
    json.dump(config, sys.stdout, indent=2, ensure_ascii=False)
    print("无新模型需要添加", file=sys.stderr)
    sys.exit(0)

for model_id in new_ids:
    new_model = {
        'id': model_id,
        'name': model_id,
        'api': 'openai-completions',
        'reasoning': False,
        'input': ['text'],
        'cost': {'input': 0, 'output': 0, 'cacheRead': 0, 'cacheWrite': 0},
        'contextWindow': 200000,
        'maxTokens': 8192
    }
    models.append(new_model)
    print(f'  ✅ 已添加: {model_id} (默认: 纯文本, 128K)', file=sys.stderr)

json.dump(config, sys.stdout, indent=2, ensure_ascii=False)
print(f'\n共新增 {len(new_ids)} 个模型', file=sys.stderr)
PYEOF
    # 校验输出是合法 JSON
    python3 -c "import json; json.load(open('$TMP_FILE.out'))" || { echo "ERROR: 输出不是合法 JSON，放弃更新"; rm -f "$TMP_FILE.out"; exit 1; }

    # 原子替换
    cp "$TMP_FILE.out" "$CONFIG_FILE"
    rm -f "$TMP_FILE.out"
    echo "✅ 配置已安全更新"
else
    echo ""
    echo "配置已是最新，无需更新"
fi

echo ""
echo "=== 完成 ==="
