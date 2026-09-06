#!/usr/bin/env bash
# 本地一键验证。CI 跑的就是这些步骤;本地红了别提 PR。
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== 1/4 engine: swift test"
( cd Packages/FreedomEngine && swift test )

echo "== 2/4 xcodegen"
command -v xcodegen >/dev/null || { echo "brew install xcodegen"; exit 1; }
xcodegen generate >/dev/null

echo "== 3/4 swiftlint --strict"
command -v swiftlint >/dev/null || { echo "brew install swiftlint"; exit 1; }
swiftlint --strict

echo "== 4/4 app build+test (simulator)"
UDID=$(xcrun simctl list devices available --json | python3 -c "import sys,json; d=json.load(sys.stdin)['devices']; c=[x for k,v in d.items() if 'iOS' in k for x in v if x['name'].startswith('iPhone')]; print(c[-1]['udid'])")
mkdir -p artifacts
xcodebuild -project WealthClock.xcodeproj -scheme WealthClock \
  -destination "platform=iOS Simulator,id=$UDID" \
  -resultBundlePath "artifacts/Tests-$(date +%s).xcresult" \
  CODE_SIGNING_ALLOWED=NO test -quiet
echo "== ALL GREEN"
