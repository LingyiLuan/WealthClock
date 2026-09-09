#!/usr/bin/env bash
# 本地化审计:WealthClock/ 下 .swift 里出现在字符串字面量中的 CJK,
# 必须走 String(localized:)/LocalizedStringKey/SwiftUI 字面量 API,或显式标注:
#   行级豁免 // l10n-ignore;文件级豁免(前 5 行)// l10n-ignore-file(设计/玄学层)。
# 发现未豁免的硬编码中文 → 报错退出(接入 verify.sh 与 CI Policy)。
set -uo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=en_US.UTF-8
FAIL=0
ALLOWED='String\(localized:|LocalizedStringKey\(|\.value\("|(Text|Button|Section|Label|Toggle|Link|DatePicker|TextField|SharePreview|navigationTitle|confirmationDialog)\("'
while IFS= read -r file; do
  head -5 "$file" | grep -q "l10n-ignore-file" && continue
  while IFS= read -r hit; do
    line_no="${hit%%:*}"
    content="${hit#*:}"
    case "$content" in *l10n-ignore*) continue ;; esac
    echo "$content" | grep -qE '^[[:space:]]*//' && continue
    echo "$content" | grep -qE "$ALLOWED" && continue
    echo "::error file=$file,line=$line_no::硬编码中文文案未本地化: ${content}"
    FAIL=1
  done < <(grep -nE '"[^"]*[一-鿿][^"]*"' "$file" || true)
done < <(find WealthClock -name '*.swift')
if [ "$FAIL" = 0 ]; then echo "l10n audit: clean"; fi
exit $FAIL
