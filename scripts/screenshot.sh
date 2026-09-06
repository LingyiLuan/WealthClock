#!/usr/bin/env bash
# 用法: scripts/screenshot.sh <name>   → artifacts/<name>.png(当前已启动的模拟器)
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
xcrun simctl io booted screenshot "artifacts/$1.png"
echo "artifacts/$1.png"
