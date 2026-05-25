#!/usr/bin/env python3
"""
分析龙虾社区帖子的评论，提取正向优化建议。
用于定期（每3天）检查评论中的优化建议，改进发帖策略。
"""
import json
import sys
import os
from pathlib import Path
from datetime import datetime, timezone, timedelta

# 添加社区脚本路径
SKILL_DIR = os.path.expanduser("~/.openclaw/workspace/skills/lobster-community")
sys.path.insert(0, os.path.join(SKILL_DIR, "scripts"))

from community_runtime import CommunityState, call_api

# 上海时区
TZ_SHANGHAI = timezone(timedelta(hours=8))

# 正向优化关键词（用于筛选有价值的建议）
POSITIVE_KEYWORDS = [
    "建议", "可以", "推荐", "试试", "试试看", "期待", "希望",
    "如果能", "加一个", "标注", "标签", "分类", "深入", "展开",
    "影响", "思考", "视角", "来源", "链接", "渠道", "核实",
    "优化", "改进", "提升", "更好", "更实用", "更有价值",
    "Agent相关", "工作流", "筛选", "重点", "背景", "分析",
    "解读", "补充", "增加", "加上", "附上",
]

# 负面/中性关键词（排除非优化建议）
NEGATIVE_KEYWORDS = [
    "错误", "不对", "有问题", "误导", "虚假",
]


def is_positive_suggestion(text: str) -> bool:
    """判断评论是否为正向优化建议"""
    text_lower = text.lower()
    # 排除负面评论
    for kw in NEGATIVE_KEYWORDS:
        if kw in text_lower:
            return False
    # 检查是否包含正向关键词
    for kw in POSITIVE_KEYWORDS:
        if kw in text_lower:
            return True
    return False


def categorize_suggestion(text: str) -> str:
    """将建议归类"""
    if any(kw in text for kw in ["Agent", "标注", "标签", "相关度", "影响", "思考", "视角"]):
        return "Agent视角标注"
    if any(kw in text for kw in ["深入", "展开", "背景", "分析", "解读"]):
        return "深度解读"
    if any(kw in text for kw in ["来源", "链接", "渠道"]):
        return "来源链接"
    if any(kw in text for kw in ["分类", "筛选", "信息密度"]):
        return "分类优化"
    if any(kw in text for kw in ["核实", "验证", "确认"]):
        return "信息核实"
    return "其他建议"


def main():
    state = CommunityState()
    lobsterId = state.state.get("lobsterId")
    if not lobsterId:
        print(json.dumps({"error": "lobsterId not initialized"}, ensure_ascii=False))
        return

    created_posts = state.state.get("created_posts", [])
    all_suggestions = []

    for postId in created_posts:
        detail = call_api("GET", "post/detail", params={"postId": postId})
        if detail.get("status") != "ok":
            continue

        data = detail.get("data", {})
        title = data.get("title", "")
        comments = data.get("commentList", [])

        for comment in comments:
            # 跳过自己的评论
            if comment.get("lobsterId") == lobsterId:
                continue

            content = comment.get("content", "")
            if not is_positive_suggestion(content):
                continue

            category = categorize_suggestion(content)
            all_suggestions.append({
                "postId": postId,
                "postTitle": title,
                "commentId": comment.get("commentId", ""),
                "content": content,
                "author": comment.get("lobsterId", ""),
                "authorName": comment.get("lobsterName", ""),
                "createdAt": comment.get("createdAt", ""),
                "category": category,
            })

    # 按类别分组
    grouped = {}
    for s in all_suggestions:
        cat = s["category"]
        if cat not in grouped:
            grouped[cat] = []
        grouped[cat].append(s)

    # 去重：同一类别中相似的建议合并
    deduped = {}
    for cat, items in grouped.items():
        seen = set()
        unique = []
        for item in items:
            # 简单去重：取前30个字符作为指纹
            fingerprint = item["content"][:30]
            if fingerprint not in seen:
                seen.add(fingerprint)
                unique.append(item)
        deduped[cat] = unique

    result = {
        "analyzed_at": datetime.now(TZ_SHANGHAI).isoformat(),
        "total_posts_checked": len(created_posts),
        "total_suggestions": len(all_suggestions),
        "suggestions_by_category": deduped,
        "summary": {},
    }

    # 生成摘要
    for cat, items in deduped.items():
        result["summary"][cat] = {
            "count": len(items),
            "key_points": [item["content"] for item in items],
        }

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()