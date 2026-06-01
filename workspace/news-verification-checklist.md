# AI 新闻验证 Checklist

> 用于每日早报、AI 周报的新闻真实性验证。宁可少发一条，不发一条假新闻。

## 快速三步验证

```
1. 搜英文关键词 → 看有没有 The Verge / TechCrunch / 官方博客报道
2. 查官网 News 页面 → 直接看原始公告
3. 看 HN 评论区 → Hacker News / Reddit r/MachineLearning 讨论往往能快速揭穿
```

## 🚩 红旗信号（越多越危险）

- [ ] 数字太「整」（如 SWE-Bench 刚好 80.0%、AIME 满分）
- [ ] 没有原始链接，只有转述
- [ ] 模型/产品名不存在或跳号（如 GPT-5.2 跳过 5.3/5.4/5.5）
- [ ] 只有中文源，搜不到英文报道
- [ ] 声称的发布日期与官网实际内容不符
- [ ] 数据与已知事实矛盾

## 验证分级

| 级别 | 适用场景 | 验证方式 |
|------|---------|---------|
| 🟢 常规 | 社会热点、财经动态 | 2+ 独立来源交叉确认 |
| 🟡 科技/AI | 产品发布、模型更新、融资 | 必须找到英文一手来源 |
| 🔴 重大 | 新模型发布、收购、CEO 变动 | 必须直接抓取官方公告原文 |

## 可信信息源

### 一手来源（最优先）
- OpenAI: openai.com/news/
- Google AI: blog.google/technology/ai/
- Anthropic: anthropic.com/news
- Meta AI: ai.meta.com/blog/
- Microsoft AI: blogs.microsoft.com/ai/
- 各公司官方博客

### 权威媒体
- The Verge (theverge.com)
- TechCrunch (techcrunch.com)
- Ars Technica (arstechnica.com)
- Wired (wired.com)

### 社区验证
- Hacker News (news.ycombinator.com)
- Reddit r/MachineLearning

### 中文参考（不可作为唯一来源）
- 量子位
- 机器之心
- 36氪

## 验证失败处理

- 无法通过验证 → 直接丢弃
- 疑似但无法确认 → 丢弃
- 当天可验证新闻不足 5 条 → 只发验证过的，不凑数
- 不确定的信息 → 标注「未经官方确认」