# AGENTS.md — WealthClock 智能体作业手册

> 所有在本仓库工作的编码智能体(Claude Code、Codex、Cursor 及其他)必须先读本文件。
> 产品规格在 `docs/BRIEF.md`,本文件只讲**怎么干活、怎么被验证、怎么做决定**。
> 人类维护者:Rinto(@LingyiLuan)。人类持有合并权;智能体持有提案权与自证权。

---

## 0. 三句话原则

1. **不信任,只验证。** 智能体的输出不靠"看起来对"被接受,靠 CI、独立测试集、截图与运行证据被接受。
2. **智能体自己验证自己。** 写完代码不是终点:构建、跑测试、启动模拟器、操作 UI、截图、把证据贴进 PR,这些都是同一个任务的一部分。
3. **策略持有合并键,不是人也不是智能体。** 分支保护 + CI + 变更预算决定一个 PR 能不能进 main;人在被验证过的变更上做最后判断,而不是在原始 diff 上做。

---

## 1. 技术栈(已决定,见 `docs/adr/0001-tech-stack.md`)

| 层 | 选择 | 不选什么 |
|---|---|---|
| 平台 | iOS 17+,Swift 5.9,SwiftUI | UIKit 主导、跨平台框架 |
| 项目文件 | **XcodeGen**(`project.yml` 生成 `.xcodeproj`) | 手工维护 pbxproj(智能体改它必冲突) |
| 核心逻辑 | `Packages/FreedomEngine` 独立 Swift Package,只依赖 Foundation | 把公式写进 View |
| 持久化 | SwiftData,本地 | 云同步、账号 |
| 图表 | Swift Charts | 第三方图表库 |
| 支付 | StoreKit 2,非消耗型买断 | Stripe/支付宝/任何外部支付 |
| 字体 | 系统 New York / SF Mono + OFL 毛笔字体(Ma Shan Zheng) | 任何未授权字体 |
| 测试 | XCTest;引擎金标固件 `golden.json`(语言无关,供未来 TS 版复用) | 无测试的"看起来能跑" |
| 代码规范 | SwiftLint(`.swiftlint.yml`)+ SwiftFormat | 各写各的风格 |
| CI | GitHub Actions,macOS runner | 只在本机验证 |
| 联网 | **v1 零联网** | 任何 SDK、分析、崩溃上报 |

---

## 2. 仓库地图

```
AGENTS.md                 ← 你正在读的
CLAUDE.md                 ← Claude Code 入口,导入本文件与 BRIEF
project.yml               ← XcodeGen 项目定义(改这个,不改 .xcodeproj)
Packages/FreedomEngine/   ← 引擎:纯 Swift,可 `swift test`
  Tests/.../Fixtures/golden.json   ← 独立评测集,智能体只读(CODEOWNERS 保护)
WealthClock/              ← App target(SwiftUI)
docs/BRIEF.md             ← 产品与工程规格(引擎公式、页面验收、里程碑)
docs/adr/                 ← 决策记录(见 §5)
docs/research/            ← 差评研究结论、科学依据与文献
docs/design/*.html        ← 设计稿(浏览器打开看,不要猜)
.claude/skills/           ← 项目技能(见 §6)
.github/                  ← CI、PR 模板、CODEOWNERS
scripts/verify.sh         ← 本地一键验证(CI 跑的就是它)
```

---

## 3. 工作流

```
Issue / 里程碑任务
  → 分支  m<N>/<slug>            (如 m1/engine-golden-tests)
  → 小 PR:≤ 400 行变更,单一目的
  → 自证:scripts/verify.sh 全绿 + 运行证据贴进 PR(见 §4)
  → CI 绿 + 变更预算通过 + 受保护路径未被触碰
  → 议会评审(见 §5)以评论形式附在 PR 上
  → 策略自动合并(L1–L3;开 PR 后立即 gh pr merge --auto --squash)/ L0 需人类事前打标签
  → 人类合并后审阅(ADR-0004);发现问题说"revert #N",见 §4.4
```

**分支规则**
- `main` 受保护:禁止直接推送,必须 PR,CI 必须绿。
- 一个 PR 只做一件事。里程碑再大也拆成多个 PR。
- 每个 PR 描述使用 `.github/pull_request_template.md`,**"证据"一节不能为空**。

**变更预算**(策略检查,机械执行)
- 代码 PR ≤ 400 行;文档/本地化 PR 不限。
- 触碰 `Packages/FreedomEngine/Tests/**/Fixtures/`、`.github/`、`AGENTS.md`、`CLAUDE.md` 的 PR 自动升级为 L0,必须人类逐行审。

---

## 4. 信任阶梯与自证

### 4.1 信任等级

| 级 | 谁审 | 合并 | 适用 |
|---|---|---|---|
| **L0** | 人类逐行(事前,打 `L0-human-reviewed` 标签) | 人类批准后策略执行 | 引擎参数、金标固件、支付、CI/工作流、本文件 |
| **L1** | CI + 人类合并后看 diff | **策略自动**(ADR-0004) | 新功能、新页面(默认级) |
| **L2** | CI + 议会评审 + 人类合并后看证据 | **策略自动**(ADR-0004) | 已有页面的迭代、样式、重构 |
| **L3** | CI + 策略 | **策略自动** | 允许名单:`docs/**`(不含 adr)、`*.xcstrings` 本地化、`docs/design/**` |

**合并纪律**:智能体开 PR 后立即 `gh pr merge --auto --squash`,CI 绿即自动合并;人类合并后审阅,发现问题走 §4.4 回滚。

**升级规则**:同一类任务连续 5 个 PR 人类零改动 → 该类任务升一级;任何一次回滚 → 降一级。升降级记录写在 `docs/adr/`。

### 4.2 自证清单(Definition of Done)

一个 PR 只有在下列全部为真时才算完成:

- [ ] `scripts/verify.sh` 本地全绿(构建 + 引擎测试 + App 测试 + SwiftLint)
- [ ] 涉及 UI 的变更:**智能体启动模拟器并导航到目标页面后停下**,由人类目视验收并在 PR 评论写 UI ✓ 或修改点;仅人类明确要求时才截图
- [ ] 涉及引擎的变更:金标测试全绿,且 PR 里打印一份示例 Profile 的输出对比(改前/改后)
- [ ] 涉及支付的变更:用 `.storekit` 配置文件走完 购买→解锁→删除重装→恢复 四步,截图
- [ ] 新增的每个数字参数都有出处注释或 `TODO(calibrate)` 标记
- [ ] 没有引入联网调用、第三方 SDK、未授权资源
- [ ] PR 描述的"证据"一节包含命令输出与截图,而不是"已测试"三个字

**证据优先于断言。** "我验证过了"不是证据;终端输出和截图才是。

### 4.3 智能体的自证工具

用 `.claude/skills/ios-self-verify` 技能。它封装了:构建、测试、`xcrun simctl` 启动模拟器、安装、截图、录屏、读取控制台日志。**智能体应当像用户一样操作 App 来验证自己的工作**,而不是只看代码。

---

### 4.4 回滚协议(ADR-0004)

人类在 Issue 或聊天里说"revert #N" → 智能体执行 `gh pr revert N`(或等价的 revert PR),CI 绿后同样 `--auto --squash` 合并,并按 §8 汇报:回滚了什么、为什么、受影响的后续 PR。任何一次回滚 = 该类任务信任降一级(§4.1 升降级规则)。

---

## 5. 议会协议(Council)——决策必须被四个视角验证

**何时触发**:任何一个"决定",包括但不限于——新增/删除页面、改问卷题目、改引擎参数、定价与付费墙、文案语气、新增依赖、架构变更、上架元数据。

**怎么做**:智能体写一份 ADR(`docs/adr/NNNN-<slug>.md`,模板见 `0000-template.md`),其中**四个角色各写一节**,每节必须有"证据来源",没有证据的意见写"无证据,仅直觉"。

| 角色 | 问的问题 | 必须引用的证据 |
|---|---|---|
| **产品经理** | 用户真的要这个吗?差评数据怎么说?竞品怎么做的? | `docs/research/reviews-findings.md`;必要时用 `appstore-review-research` 技能重新抓取;App Store 榜单与竞品页面 |
| **UI 设计师** | 符合设计系统吗?像素/古籍/朱砂的分工守住了吗?可分享吗? | `docs/design/*.html`;`wealthclock-design-system` 技能;HIG |
| **iOS 工程师** | 平台上正确的做法是什么?审核会怎么看?性能与可访问性? | Apple 官方文档;App Store 审核指南条款号;`engine-verification`/`ios-self-verify` 技能 |
| **全栈工程师** | 这个逻辑将来 H5 版能复用吗?数据可导出吗?有没有把状态锁进 iOS 独有 API? | `golden.json` 是否覆盖;引擎是否仍是纯 Foundation |

**规则**
- 四个角色**必须互相引用并回应**对方的反对意见,不许各说各话。
- 意见一致 → ADR 状态 `accepted`,继续干。
- 意见冲突 → ADR 状态 `needs-human`,把冲突点浓缩成一段话 @Rinto,**不许自行仲裁产品问题**;技术问题可以由 iOS 工程师视角仲裁并注明。
- ADR ≤ 1 页。写不进一页说明还没想清楚。
- 用 `council-decision` 技能生成 ADR 骨架。

---

## 6. 项目技能(`.claude/skills/`)

| 技能 | 用途 | 触发 |
|---|---|---|
| `council-decision` | 生成四角色 ADR,强制证据引用 | 任何"决定"之前 |
| `appstore-review-research` | 抓取指定 App 的低分评论并聚类主题 | 产品经理视角需要新证据时 |
| `wealthclock-design-system` | 色板、字体、像素/古籍分工、组件规则 | 写任何 View 之前 |
| `engine-verification` | 金标固件、不变量测试、参数出处检查 | 碰 `FreedomEngine` 之前 |
| `ios-self-verify` | 构建/测试/模拟器/截图/录屏一条龙 | 每个 PR 完成前 |

技能是这个项目积累的"如何把事做对"的知识。**发现一个新的可复用做法时,更新对应技能,而不是写在 PR 评论里然后被遗忘。** 技能的修改走 L1。

---

## 7. 护栏(违反任何一条 = PR 直接关闭)

1. 不联网。不加任何 SDK。不加分析。不加崩溃上报。
2. 不写密钥、账号、真实姓名、手机号进仓库。`.gitignore` 已覆盖常见位置,但你要自己看。
3. 不复制第三方图像、字体、文案。花边程序生成,字体 OFL,文案原创。
4. 不接外部支付。不在 App 内引导去网站付款。
5. 不改 `golden.json` 与金标测试的期望值。发现引擎与固件冲突,**改引擎或开 ADR 质疑固件,不许改数字让测试变绿**。
6. `birthDate` 不许进入任何计算路径。有一条单测专门守这个。
7. 不 force push,不改历史,不删别人的分支。
8. 产品决策不猜:定价、文案语气、功能取舍——停下来开 ADR 或 @Rinto。
9. 不在 PR 里说"已测试"而不附证据。

---

## 8. 与人类沟通

- **里程碑报告**格式:做了什么 / 证据(链接到 PR 与截图)/ 未决问题(编号)/ 下一步 / 需要人类做的事。
- **问题批量问**:一个里程碑攒到一起问,不要每十分钟一个。
- **不沉默假设**:凡是本文件与 BRIEF 都没写的产品选择,当作未决问题提出,附你的建议与理由。
- 人类不在线时,继续做**不依赖该决定**的工作,不要停摆。

---

## 9. 第一次开工(M0)

```bash
brew install xcodegen swiftlint swiftformat
xcodegen generate
scripts/verify.sh          # 期望:全绿,包含引擎金标测试
```
如果 `verify.sh` 第一次就红,**修红是 M0 的一部分**——尤其是 `FreedomEngine` 里的初版实现由另一个智能体在无编译环境下写成,存在编译错误是预期内的;金标固件的数字不许动。
