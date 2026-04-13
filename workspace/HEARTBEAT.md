# HEARTBEAT.md

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

---

## 每日AI早报 - 启动检查

每次心跳时检查以下逻辑：

1. 读取 `memory/ai-news-state.json`，检查上次发送日期
2. 如果今天的日期不等于上次发送日期，并且当前时间 >= 6:00：
   - 尝试发送每日新闻早报
   - **发送流程：**
     a. 用 `web_fetch` 分别抓取以下新闻源，搜索多个类别：
        - 百度新闻（搜索关键词轮流）：AI人工智能最新进展、国际时事、科技互联网、经济财经
        - 今日头条：AI人工智能、国际新闻、科技、财经
        - 腾讯新闻：AI、国际、科技、财经
     b. 新闻类别范围：
        - 🤖 AI / 人工智能
        - 🌍 国际大事
        - 💻 科技互联网
        - 💰 经济财经
        - 🔬 前沿科技（航天、生物、能源等）
        - ❌ 不包含：八卦娱乐、明星、综艺
     c. 合并去重后，每个类别挑选 1-2 条重要新闻，总共 5-10 条，整理成早报格式发送
     d. 如果国内源全部失败，用 `web_fetch` 抓取 Hacker News (https://news.ycombinator.com/) 作为备用
     e. 如果全部失败，更新 `memory/ai-news-state.json` 的 note 为失败原因，**不更新日期**，下次心跳继续重试
     f. 如果当前时间 >= 21:00（下班后），停止重试，note 标记为"超过推送时间窗口"
   - 发送成功后更新 `memory/ai-news-state.json` 的日期为今天
   - **每周日附加 AI 大厂周报：** 如果今天是周日，在每日早报之后追加一份 **AI 大厂周报**
     - **覆盖厂家：**
       - 国内：百度、阿里、字节、腾讯、智谱、月之暗面、MiniMax、DeepSeek、零一万物、百川
       - 海外：OpenAI、Google、Anthropic、Meta、Microsoft、xAI、Mistral
     - **关注维度：** 新模型/产品发布、技术迭代与能力提升、API价格策略变动、重要开源项目、人事变动
     - **信息源：**
       - 国内：量子位、机器之心、36kr AI频道、百度新闻（搜索"AI大模型"/"人工智能"等关键词）
       - 海外：The Verge AI、TechCrunch AI、Hacker News（AI相关）、各厂家官方博客
     - **格式：** 按厂家分组，每个厂家列出本周重要动态，最后加一段简要总结趋势
     - 如果周日早报发送失败，周报不单独重发，等下周日一起
3. 如果今天已经发送过，跳过（HEARTBEAT_OK）

## 前端技术大事监控

每次心跳时：
1. 读取 `memory/frontend-tech-state.json`，检查上次检查时间
2. 如果距上次检查 >= 2 小时：
   - 用 `web_fetch` 抓取以下前端技术源：
     - GitHub Trending (前端相关): 通过搜索 GitHub Trending 页面
     - Hacker News: 已在早报中覆盖，重点关注前端相关
     - 掘金前端频道、InfoQ 前端等国内源
   - 如果发现重大事件（如 React/Vue/Angular 新版本发布、重大框架更新、Breaking Change 等），主动推送
   - 如果没有大事，不推送（保持安静）
   - 更新 `memory/frontend-tech-state.json` 的上次检查时间
3. **判断"大事"标准：** 主流框架/工具大版本发布（如 Vue 4、React 20）、知名项目重大更新、影响广泛的安全漏洞、重大 API 变更等。普通小版本迭代不推送。
