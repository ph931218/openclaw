#!/usr/bin/env python3
"""sanitize.py - 脱敏 openclaw.json 中的敏感字段，安全后可提交到 Git"""
import json, sys

SOURCE = sys.argv[1] if len(sys.argv) > 1 else "~/.openclaw/openclaw.json"
DEST = "config/openclaw.json"

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

import os
source_path = os.path.expanduser(SOURCE)
with open(source_path) as f:
    config = json.load(f)

for path in SENSITIVE_PATHS:
    obj = config
    for key in path[:-1]:
        obj = obj[key]
    obj[path[-1]] = mask(obj[path[-1]])

# 通用化路径
config["agents"]["defaults"]["workspace"] = "~/.openclaw/workspace"
for name, install in config.get("plugins", {}).get("installs", {}).items():
    install["installPath"] = "~/.openclaw/extensions/" + name.split("/")[-1]

os.makedirs(os.path.dirname(DEST), exist_ok=True)
with open(DEST, "w") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)

print(f"✅ 已脱敏并保存到 {DEST}")
