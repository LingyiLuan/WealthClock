---
name: appstore-review-research
description: 抓取一批 App Store 应用(默认灵性/塔罗/占星/理财类)的低分评论并做主题聚类,产出可引用的痛点证据表。产品经理视角在议会里需要"用户到底在骂什么"的数据、做竞品对比、决定功能取舍或付费墙位置、准备上架文案时使用;用户说"调研一下""看看差评""竞品怎么样"时也要用。
---

# App Store Review Research

## 抓
```bash
python3 .claude/skills/appstore-review-research/scripts/scrape_reviews.py
```
- 改 `TARGET_APPS` 与 `COUNTRIES` 以适配本次问题。脚本用 iTunes Search API 解析 App ID,**先人工核对解析结果**再看数据。
- 每 App 每国最多 500 条最新评论(RSS 上限),是近期快照不是全历史——结论里必须注明。
- 若 `requests` 不可用(PEP 668),改用标准库 `urllib`;若 DNS 被代理劫持,`curl --resolve` 或 DoH 绕过。

## 聚
对 `reviews_low_star.csv`:
1. 主题词典(可扩):价格/订阅/付费墙、更新变差、登录/丢数据、准确度、AI 感、闪退、UI、客服/退款、内容泛泛、广告、缺日志/历史。
2. **去噪**:`pattern` 命中多为 App 名"The Pattern";`log` 命中多为 "logged out"。先剔再算。
3. 输出:全品类 Top 10(命中数、占比)/ 每 App Top 3 / 关注主题的精确子集 CSV。
4. 每条结论附 2–3 条代表性引用(改写,不整段复制)。

## 用
写进 `docs/research/reviews-findings.md`,格式:结论 → 数据 → 对本产品的含义。议会里引用时写到"哪一条"。
已有的基线结论(2026-09,15 App × 4 国,4,416 条 ≤3 星)见该文件。
