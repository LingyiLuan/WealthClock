#!/usr/bin/env bash
# 上架截图(BRIEF §8 M8):6.9"(iPhone 16 Pro Max)与 6.5"(iPhone 11 Pro Max)各 5 张。
# 产物:artifacts/screenshots/<设备>-<页面>.png。设备缺失(如本机 Xcode 无 iPhone 16)会警告并跳过。
set -euo pipefail
cd "$(dirname "$0")/.."

APP=$(ls -d ~/Library/Developer/Xcode/DerivedData/WealthClock-*/Build/Products/Debug-iphonesimulator/WealthClock.app 2>/dev/null | head -1)
[ -n "$APP" ] || { echo "先跑 scripts/verify.sh 生成构建"; exit 1; }
mkdir -p artifacts/screenshots

DEVICES=("iPhone 16 Pro Max" "iPhone 11 Pro Max")
declare -a SHOTS=(
  "bill:-bill:6"
  "reveal:-reveal:4"
  "quiz-trading:-quiz -quizStep 9:3"
  "scenarios:-scenarios:4"
  "history:-history -seedSample:4"
  "paywall:-paywall:3"
)

for DEVICE in "${DEVICES[@]}"; do
  UDID=$(xcrun simctl list devices available | grep -F "$DEVICE (" | head -1 | grep -oE '[0-9A-F-]{36}' || true)
  if [ -z "$UDID" ]; then
    TYPE=$(xcrun simctl list devicetypes | grep -F "$DEVICE (" | grep -oE 'com\.apple\.[A-Za-z0-9.-]+' | head -1 || true)
    if [ -n "$TYPE" ]; then
      echo "创建模拟器:$DEVICE"
      UDID=$(xcrun simctl create "$DEVICE" "$TYPE" 2>/dev/null || true)
    fi
  fi
  if [ -z "$UDID" ]; then
    echo "警告:本机 Xcode 无 $DEVICE(6.9\" 需新版 Xcode),跳过"
    continue
  fi
  SLUG=$(echo "$DEVICE" | tr ' ' '-')
  xcrun simctl boot "$UDID" 2>/dev/null || true
  xcrun simctl install "$UDID" "$APP"
  for SHOT in "${SHOTS[@]}"; do
    NAME="${SHOT%%:*}"; REST="${SHOT#*:}"; ARGS="${REST%%:*}"; WAIT="${REST##*:}"
    xcrun simctl terminate "$UDID" app.wealthclock.ios 2>/dev/null || true
    # shellcheck disable=SC2086
    xcrun simctl launch "$UDID" app.wealthclock.ios $ARGS >/dev/null
    sleep "$WAIT"
    xcrun simctl io "$UDID" screenshot "artifacts/screenshots/$SLUG-$NAME.png"
    echo "✓ $SLUG-$NAME.png"
  done
  xcrun simctl terminate "$UDID" app.wealthclock.ios 2>/dev/null || true
done
ls -la artifacts/screenshots/ | tail -12
