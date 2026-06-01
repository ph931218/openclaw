# MEMORY.md - 长期记忆

## 老大的规矩 (2026-04-02)

1. **不私自修改文件** — 除非得到明确授权
2. **不随意读取敏感信息** — 环境变量、账号信息等
3. **删除文件必须询问** — 每次都要确认
4. **智谱 API key 仅用于搜索实时新闻** — 其他情况禁止使用
5. **下班后不主动消耗 token** — 每天20:00之后，不主动执行心跳检查、搜索新闻等消耗 token 的动作，除非老大主动找我说话
6. **其他平台消息可以使用 token** — 当接收到其他地方的机器人发来的消息时，可以使用 token（如搜索等）
8. **图片识别失败自动换模型** — 配置里的 input 字段不一定准确。要根据自己对模型能力的了解来判断哪些真正支持 vision，然后逐个尝试，找到能用的就改配置文件。**实测结果（2026-04-08 OneAPI）：MiniMax-M2.1 ✅ | MiniMax-M2.5 ✅ | MiniMax-M2.7 ✅ | Claude Haiku 4.5 ❌（ARN映射缺失）| Claude Sonnet 4.6 ❌（base64转换失败）| Claude Opus 4.6 ❌ | GLM-5-Turbo ❌ | GLM-5 ❌ | Kimi-K2.5 ❌ | MiniMax-M2-Stable ❌（负载高）| 智谱Coding Plan ❌（无视觉模型）。当前 imageModel = oneapi/MiniMax-M2.7
9. **OpenClaw 新版本直接更新** — 老大说之后有新版本不用问，直接帮他更新就行（2026-04-17）
10. **对话期间暂停所有定时任务** — 当老大正在跟我对话时（主会话有活跃消息往来），所有 cron 定时任务和心跳检查任务暂停执行，等对话结束后再恢复（2026-05-15）
11. **新闻早报必须验证** — 每条入选早报的新闻必须经过验证流程（红旗信号扫描 → 交叉验证 → 官方溯源），详见 HEARTBEAT.md 和 news-verification-checklist.md。宁可少发，不发假新闻（2026-05-27）

## 教训

1. **修改模型配置要小心** — 切换默认模型后可能导致前缀匹配错误（如 `anthropic/GLM-5-Turbo`），导致系统无法找到模型而瘫痪。修改后要确认模型 ID 和 provider 前缀匹配正确。
2. **智谱 Coding Plan 不支持视觉模型** — Coding Plan 的端点 `/api/coding/paas/v4` 仅限代码场景，可用模型（glm-5.1/5/5-turbo/4.7/4.6/4.5/4.5-air）都不支持图片输入，会返回 429。
3. **OneAPI 渠道配置可能不准** — 模型列表里显示的模型不一定真的能转发成功（如 Claude 的 ARN 映射缺失、GLM 不转发图片参数），需要实测验证。
4. **SSRF 私网拦截导致模型不可用** — OpenClaw 的 fetch guard 默认禁止私网 IP 请求。如果 provider baseUrl（如 `oneapi-comate.baidu-int.com`）解析到内网 IP，所有模型请求会被拦截，报错只显示泛化的 `network connection error`。修复：在 provider 配置中设置 `request.allowPrivateNetwork: true`。排查模型不可用时优先检查此项。

这些是红线，必须遵守。

---
