---
name: engine-verification
description: 修改或新增 Packages/FreedomEngine 里任何东西(公式、参数、归因、问卷评分)之前和之后必须用的验证流程:先跑金标测试,检查每个数字的出处注释,确认 birthDate 不变量与情景单调性,输出改前/改后示例对比。用户提到"引擎""公式""参数""校准""自由年龄算得不对"时也要用。
---

# Engine Verification

## 不可协商
- `Tests/FreedomEngineTests/Fixtures/golden.json` **只读**。它是独立于你的评测集。测试红了,改引擎,或开 ADR 质疑固件——不许改期望值。
- `EngineParams.swift` 里每个数字必须有出处注释或 `TODO(calibrate)`。改它 = L0 PR,PR 需要 `L0-human-reviewed` 标签。
- `birthDate` 不许出现在 `Profile.swift` 以外的引擎源码里(SwiftLint 自定义规则 + 单测双重守护)。

## 改动前
```bash
cd Packages/FreedomEngine && swift test 2>&1 | tail -20
swift run --package-path . 2>/dev/null || true   # 无可执行目标,忽略
```
记录当前 `Profile.sample` 的三情景与归因输出(写一个临时测试打印,或在 App 的 Debug 画廊页看)。

## 改动后
1. `swift test` 全绿。
2. 不变量:
   - 情景单调:乐观 ≤ 中性 ≤ 悲观(`testScenariosAreOrdered`)。
   - 更高储蓄率 → 更早或相同自由年龄(补一条测试)。
   - `birthDate` 改变 → 输出完全相同。
   - 归因每一项单独可复现:把该因素中性化重跑,差值一致。
3. 在 PR 里贴 改前/改后 的示例输出表(三情景年龄 + 每个归因年数)。
4. 若任何示例变化超过 3 年,解释原因;解释不了就不要合。

## 校准时(替换 TODO(calibrate))
- 数据来源写全:机构、年份、表号或 URL。
- 一个参数一个 PR。
- 同步更新 `docs/research/science-basis.md`。
