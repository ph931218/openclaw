# HEARTBEAT.md

## 行为准则

- **执行过程中保持安静** — 不输出任何进度提示（如「正在抓取新闻...」「开始同步模型...」等）
- **完成后才说话** — 只在任务成功完成或需要老大关注时才发消息
- **失败时简短告知** — 一句话说明失败原因即可

## 每日综合早报

⚠️ 静默执行：抓取新闻、筛选、格式化全程不输出任何中间状态。

每次心跳时检查以下逻辑：

1. 读取 `memory/ai-news-state.json`，检查上次发送日期
2. 如果今天的日期不等于上次发送日期，并且当前时间 >= 8:00：
   - 尝试发送每日新闻早报
   - **发送流程：**
     a. 执行 cn-hot-trends skill 脚本抓取热榜数据：
        ```bash
        cd ~/.openclaw/workspace/skills/cn-trends-aggregator && python3 scripts/fetch_trends.py --format json --limit 15 --sources baidu,toutiao,hn,github
        ```
     b. **新闻早报部分：**
        - 类别范围：🤖 AI / 🌍 国际 / 💻 科技 / 💰 财经 / 🔬 前沿科技
        - ❌ 不包含：八卦娱乐、明星、综艺、体育（除非重大事件）
        - 从百度热榜和头条中筛选国内热点，从 HN 和 GitHub 中筛选科技/AI 热点
        - 合并去重后，按类别分组，总共 5-15 条
        - 输出为 Markdown 格式（标题 + 简要说明 + 链接）
     c. **前端大事部分：**
        - 从 HN 和 GitHub 结果中筛选前端相关大事
        - 标准：主流框架大版本发布（Vue 4、React 20 等）、重大安全漏洞、广泛影响的 Breaking Change
        - 如果有大事：在早报中追加「🔧 前端技术速递」板块
        - 如果无大事：不提及，保持安静
     d. 如果脚本执行失败，更新 note 为失败原因，**不更新日期**，下次心跳继续重试
     e. 如果当前时间 >= 21:00（下班后），停止重试，note 标记为"超过推送时间窗口"
   - 发送成功后更新 `memory/ai-news-state.json` 的日期为今天
   - **同步发帖到龙虾社区：**
     a. 从已生成的新闻早报内容中，提取核心新闻（去重、去掉 Markdown 格式符号）
     b. 构造帖子 JSON 文件：
        ```bash
        echo '{"title": "📰 每日热点速递（'$(date +%m-%d)'）", "content": "🦞 来自 桐人 的每日新闻分享\n\n{精简后的新闻列表，每条用简短一句话概括}"}' > /tmp/lobster_news_post.json
        ```
     c. 调用社区脚本发帖：
        ```bash
        python3 ~/.openclaw/workspace/skills/lobster-community/scripts/community_runtime.py create-post-with-content --post-file /tmp/lobster_news_post.json
        ```
     d. 发帖失败不影响早报流程，静默跳过即可
   - **每周日附加 AI 大厂周报：** 如果今天是周日，在早报之后追加 AI 大厂周报
     - **覆盖厂家：**
       - 国内：百度、阿里、字节、腾讯、智谱、月之暗面、MiniMax、DeepSeek、零一万物、百川
       - 海外：OpenAI、Google、Anthropic、Meta、Microsoft、xAI、Mistral
     - **关注维度：** 新模型/产品发布、技术迭代、API 价格变动、重要开源、人事变动
     - **信息源：** 量子位、机器之心、36kr AI、The Verge AI、TechCrunch AI、HN、官方博客
     - **格式：** 按厂家分组，每家列动态，最后简要趋势总结
     - 如果周日早报失败，周报不单独重发，等下周日一起
3. 如果今天已经发送过，跳过（HEARTBEAT_OK）

---

## 模型配置自动同步（每3天）

每次心跳时：
1. 读取 `memory/sync-models-state.json`，检查上次同步时间
2. 如果距上次同步 >= 3 天（72小时）：
   - 执行 `bash scripts/sync-models.sh` 同步 OneAPI 模型列表
   - 如果有变更或有结果需要关注，主动推送给老大
   - 如果无变更，保持安静
   - 更新 `memory/sync-models-state.json` 的上次同步时间
3. 安全策略：脚本本身已实现只增不删、不覆盖已有属性、JSON 校验

---

## 每周四写周报提醒

每次心跳时检查：
1. 如果今天是周四，并且当前时间 >= 17:00，并且 <= 20:00：
   - 通过微信提醒老大写周报（target: o9cq800gt_BcGQ7-E6ZZRfPQUPBw@im.wechat）
   - 更新 `memory/weekly-reminder-state.json` 的 lastSentDate 为本周四的日期
2. 如果本周四已经提醒过，跳过
