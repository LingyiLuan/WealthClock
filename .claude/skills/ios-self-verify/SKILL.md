---
name: ios-self-verify
description: 每个 PR 完成前智能体自己验证自己的一条龙流程——构建、跑测试、启动 iOS 模拟器、安装 App、导航到目标页面、截图或录屏、读取控制台日志、把证据贴进 PR。凡是要提 PR、说"做完了""改好了""测过了",或用户要求"截图看看""跑一下"时必须用;不要用"已测试"三个字替代本流程。
---

# iOS Self-Verify

原则:**像用户一样操作 App,然后把看到的贴出来。** 代码 diff 不是证据,运行结果才是。

## 一键
```bash
scripts/verify.sh            # 引擎测试 + xcodegen + swiftlint + 模拟器构建测试
```
红了先修红。不要跳过。

## 截图流程
```bash
UDID=$(xcrun simctl list devices available --json | python3 -c "import sys,json; d=json.load(sys.stdin)['devices']; c=[x for k,v in d.items() if 'iOS' in k for x in v if x['name'].startswith('iPhone')]; print(c[-1]['udid'])")
xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator
xcodebuild -project WealthClock.xcodeproj -scheme WealthClock -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath build CODE_SIGNING_ALLOWED=NO build -quiet
APP=$(find build -name "WealthClock.app" -path "*iphonesimulator*" | head -1)
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch --console-pty "$UDID" app.wealthclock.ios &   # 控制台日志会打到终端
sleep 2
scripts/screenshot.sh reveal_before     # → artifacts/reveal_before.png
```
需要走到某个页面时,用 XCUITest 或在 Debug 构建里加 `-startAt reveal` 这类启动参数(`WealthClock/App/DebugLaunch.swift`,仅 DEBUG)。

## 录屏(动效)
```bash
xcrun simctl io "$UDID" recordVideo artifacts/reveal.mov &   # Ctrl-C 停止
```
转 GIF 贴 PR:`ffmpeg -i artifacts/reveal.mov -vf "fps=15,scale=390:-1" artifacts/reveal.gif`。

## 支付四步(涉及 StoreKit 时)
用 `WealthClock/Resources/WealthClock.storekit` 配置文件在模拟器里:购买 → 解锁 → 卸载重装 → 恢复购买。每步截图。

## 贴进 PR
PR 模板"证据"一节:verify.sh 末尾 20 行 + 截图路径(上传到 PR 附件)+ 若有异常日志,原文贴出并说明。
看到自己写"应该没问题",删掉,换成命令输出。
