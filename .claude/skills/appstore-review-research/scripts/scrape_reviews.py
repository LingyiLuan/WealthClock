# -*- coding: utf-8 -*-
"""
灵性/塔罗类 App 低分评论抓取器
用途：市场调研 —— 抓取 App Store 公开 RSS 评论接口中 1-3 星评论，输出 CSV。
运行环境：你的 Mac（不需要浏览器/opencli，纯 HTTP）。
依赖：pip install requests
用法：python scrape_spiritual_app_reviews.py
输出：reviews_low_star.csv + 终端摘要

注意：
- iTunes RSS 每个 App 每个国家最多返回 10 页 x 50 条 = 500 条最新评论
- 这是 Apple 的公开接口，无需鉴权；请保持默认限速，别改小 sleep
- App ID 通过 iTunes Search API 动态解析，跑完第一步先人工核对解析结果
"""

import csv
import json
import time
import requests

# ---------- 配置 ----------
# 搜索词 -> 期望的 App 名字关键词（用于核对解析是否正确）
TARGET_APPS = {
    "Co-Star astrology": "co",
    "CHANI astrology": "chani",
    "Nebula horoscope astrology": "nebula",
    "The Pattern": "pattern",
    "Sanctuary astrology": "sanctuary",
    "Moonly moon calendar": "moonly",
    "Labyrinthos tarot": "labyrinthos",
    "Golden Thread Tarot": "golden thread",
    "Tarotoo tarot": "tarotoo",
    "Witch AI tarot": "witch",
    "Tarot Life": "tarot life",
    "A Sign spiritual": "sign",
    "Angel Number Signs": "angel number",
    "Spiritual AI": "spiritual",
    "The Moon calendar app": "moon",
}

COUNTRIES = ["us", "gb", "ca", "au"]   # 英语区先跑；想看国内加 "cn"
MAX_PAGES = 10                          # RSS 上限
LOW_STAR_MAX = 3                        # 保留 <= 3 星
SLEEP = 0.6                             # 每次请求间隔（秒）

OUT_CSV = "reviews_low_star.csv"

# ---------- 第一步：解析 App ID ----------
def resolve_app_id(term):
    url = "https://itunes.apple.com/search"
    params = {"term": term, "entity": "software", "country": "us", "limit": 3}
    r = requests.get(url, params=params, timeout=15)
    r.raise_for_status()
    results = r.json().get("results", [])
    if not results:
        return None
    top = results[0]
    return {
        "id": top["trackId"],
        "name": top["trackName"],
        "rating": top.get("averageUserRating"),
        "rating_count": top.get("userRatingCount"),
        "genre": top.get("primaryGenreName"),
    }

# ---------- 第二步：抓评论 ----------
def fetch_reviews(app_id, country, page):
    url = (
        f"https://itunes.apple.com/{country}/rss/customerreviews/"
        f"page={page}/id={app_id}/sortby=mostrecent/json"
    )
    r = requests.get(url, timeout=20)
    if r.status_code != 200:
        return []
    try:
        data = r.json()
    except json.JSONDecodeError:
        return []
    entries = data.get("feed", {}).get("entry", [])
    if isinstance(entries, dict):
        entries = [entries]
    out = []
    for e in entries:
        # 第一条 entry 有时是 App 自身信息，没有 rating 字段
        if "im:rating" not in e:
            continue
        out.append({
            "rating": int(e["im:rating"]["label"]),
            "title": e.get("title", {}).get("label", ""),
            "body": e.get("content", {}).get("label", ""),
            "version": e.get("im:version", {}).get("label", ""),
            "date": e.get("updated", {}).get("label", "")[:10],
            "author": e.get("author", {}).get("name", {}).get("label", ""),
        })
    return out


def main():
    print("=== 第一步：解析 App ID（请人工核对下面每一行是否是你要的 App）===")
    resolved = {}
    for term, expect in TARGET_APPS.items():
        info = resolve_app_id(term)
        time.sleep(SLEEP)
        if not info:
            print(f"  [MISS] {term} -> 未找到")
            continue
        flag = "OK " if expect.lower() in info["name"].lower() else "??? 请核对"
        print(f"  [{flag}] {term} -> {info['name']} (id={info['id']}, "
              f"{info['rating']}★ / {info['rating_count']} ratings)")
        resolved[info["name"]] = info["id"]

    print("\n=== 第二步：抓取低分评论 ===")
    rows = []
    for name, app_id in resolved.items():
        app_low = 0
        for country in COUNTRIES:
            for page in range(1, MAX_PAGES + 1):
                reviews = fetch_reviews(app_id, country, page)
                time.sleep(SLEEP)
                if not reviews:
                    break
                for rv in reviews:
                    if rv["rating"] <= LOW_STAR_MAX:
                        rv.update({"app": name, "country": country})
                        rows.append(rv)
                        app_low += 1
        print(f"  {name}: 累计低分评论 {app_low} 条")

    with open(OUT_CSV, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=[
            "app", "country", "date", "rating", "version",
            "title", "body", "author",
        ])
        writer.writeheader()
        writer.writerows(rows)

    print(f"\n完成：{len(rows)} 条低分评论 -> {OUT_CSV}")
    print("下一步：把 CSV 交给 Claude Code 做主题聚类（见对话里的指令）。")


if __name__ == "__main__":
    main()
