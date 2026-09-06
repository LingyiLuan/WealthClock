# WealthClock — Claude Code 开发指令書

> 把这份文件放到项目根目录,命名 `CLAUDE.md`。Claude Code 会把它当作长期上下文。
> 开工命令:`cd ~/Projects/WealthClock && claude`,然后说:"读 CLAUDE.md,从 M0 开始,每个里程碑结束向我汇报。"

---

## 0. 工作方式与安全规则(最高优先级)

1. **人先建壳。** 我(Rinto)会先在 Xcode 里用 App 模板新建项目:名称 `WealthClock`、Interface SwiftUI、Storage SwiftData、Language Swift、Bundle ID `app.wealthclock.ios`、最低版本 iOS 17.0,保存到 `~/Projects/WealthClock`,并 `git init` 做首次提交。**你在这个壳里工作,不要自己生成 .xcodeproj。**
2. **只动这个目录。** 不读、不改、不删 `~/Projects/WealthClock` 之外的任何东西。不碰其他仓库。
3. **每个里程碑一次 commit**,message 格式 `M3: reveal screen + coin toss`。不 force push,不改历史。
4. **不写任何密钥、账号、真实姓名进代码。** 不接任何分析 SDK、广告 SDK、第三方登录。
5. **不接外部支付。** 数字内容只走 StoreKit 2。看到自己想写 Stripe/支付宝/微信支付的冲动就是停下的信号。
6. **不复制任何第三方图像、字体、文案。** 字体只用 OFL 授权(见 §5),花边和像素全部程序生成。
7. **产品决策不猜。** 遇到本文档没写的产品选择(定价数字、文案语气、功能取舍),停下来问我,附上你的建议。技术实现细节你自己定。
8. **每个里程碑结束时输出**:做了什么 / 测试结果 / 未决问题 / 下一步。然后等我确认再继续。
9. 构建与测试用命令行:`xcodebuild -scheme WealthClock -destination 'platform=iOS Simulator,name=<用 xcrun simctl list devices available 找一个 iPhone>' build` 与 `... test`。任何一步红了先修红再往前走。
10. 引擎里的每一个参数都要有出处注释。**没有出处的数字标 `// TODO(calibrate)`,不许标成事实。**

---

## 1. 产品定义(一段话,别偏离)

WealthClock 是一个"用数学算命"的 iOS App:用户回答 12 个问题,App 用有文献依据的模型算出他的**财务自由年龄**(三情景:乐观/中性/悲观),用"掷铜钱→点阵数字"的仪式揭晓,再生成一张雕版钞票风格的"汇票"结果卡供分享。命理内容(八字/流年)只生成结果卡上的一行"密押"和配色,**永远不参与任何计算**。产品原则:算术必须真,玄学只是包装;免费结果完整给,付费只买深度推演;用户的历史数据永远免费可看、可导出、可删除。

---

## 2. 架构与目录

```
WealthClock/
  App/            WealthClockApp.swift, AppRouter.swift
  Engine/         纯 Swift,只 import Foundation。无 UI、无 SwiftData、无 StoreKit。
    Profile.swift        输入模型
    EngineParams.swift   全部参数 + 出处注释
    FreedomEngine.swift  模拟器 + 归因
    Scenario.swift       三情景定义
    Literacy.swift       Lusardi 三大题题库与评分
  Design/         设计系统
    Tokens.swift         色板、字体、间距
    PixelDigits.swift    5×7 点阵数字 (Canvas)
    PixelCoin.swift      11×11 像素铜钱 (Canvas)
    Guilloche.swift      雕版花边 Path 生成器
    Hexagram.swift       六爻进度条
  Features/
    Quiz/                12 题问卷(一屏一题)
    Reveal/              揭晓页
    Scenarios/           推演页(付费)
    Bill/                汇票结果卡 + 导出
    History/             历史记录
    Paywall/             付费墙
    Settings/            设置
  Persistence/    SwiftData 模型 + 导出
  Store/          StoreKit 2 封装
  Resources/      字体、String Catalog、StoreKit 配置文件
  WealthClockTests/      引擎单测(金标值)
```

**Engine 是一个独立 Swift Package**(`Packages/FreedomEngine`),App target 依赖它。这样它可以被单独测试,将来也能给 H5 版复用逻辑。

---

## 3. 引擎规格(核心,逐字实现)

### 3.1 输入

```swift
public struct Profile: Codable, Equatable {
    public var age: Int                    // 18...70
    public var region: Region              // .cnMainland, .hkTw, .sea, .northAmerica, .other
    public var currencyCode: String        // "CNY","USD","HKD","SGD","MYR"...
    public var monthlyIncome: Double       // 税后
    public var monthlyExpense: Double      // 不含房贷
    public var investableAssets: Double    // 可投资资产(不含自住房)
    public var mortgageMonthly: Double     // 0 = 无
    public var mortgageYearsLeft: Int      // 0 = 无
    public var industry: Industry          // .tech,.finance,.healthcare,.education,.manufacturing,.government,.retailService,.creative,.freelance,.other
    public var yearsExperience: Int
    public var education: Education        // .belowBachelor,.bachelor,.masterPlus
    public var tradingHabit: TradingHabit  // .indexOnly,.occasional,.weekly,.dayTrading
    public var accountTier: AccountTier    // .under100k,.k100to500k,.k500to10m,.over10m (折合 CNY)
    public var hasSideHustle: Bool
    public var literacyScore: Int          // 0...3,Lusardi 三大题答对数
    public var selfControl: Int            // 1...7,"控制支出有多难",1=毫无困难
    public var birthDate: Date?            // 仅供 Omen 层,引擎必须忽略
}
```

### 3.2 三情景参数(`EngineParams.swift`)

| 参数 | 悲观 | 中性 | 乐观 | 出处 |
|---|---|---|---|---|
| 安全提取率 | 3.5% (自由线 = 年支出 × 28.57) | 4.0% (× 25) | 4.7% (× 21.28) | Bengen 1994;Trinity 1998;Morningstar 2025 给 3.7%,Bengen 2024 上调至 4.7%;40 年以上期限研究建议 3.25–3.5% |
| 真实年化收益 | 3% | 5% | 7% | 历史真实回报区间,保守/中性/乐观 |
| 收入实际增速(峰值前) | 2% | 3% | 4% | Mincer 1974 凹型曲线;`TODO(calibrate)` 按行业数据校准 |
| 收入峰值年龄(cnMainland) | 35 | 40 | 45 | Fang & Qiu, JPE 2023:中国横截面峰值年龄已降至 35;个人生命周期曲线因队列效应更平缓,故三档递进 |
| 收入峰值年龄(其他地区) | 45 | 50 | 50 | Fang & Qiu:美国稳定在 45–50 |
| 峰值后收入实际增速 | −1% | 0% | 0% | 同上 |
| 支出实际增速 | 1% | 0% | 0% | 生活方式通胀,`TODO(calibrate)` |

**学历修正**(作用于峰值前收入增速):belowBachelor −0.5pp,bachelor 0,masterPlus +0.5pp。出处:Mincer 教育回报;`TODO(calibrate)`。

**行业修正**(作用于峰值年龄):tech −3 岁(cnMainland 下再 −2),government/healthcare/education +5 岁,其他 0。`TODO(calibrate)`,标注"行业曲线待接入国家统计局分行业工资数据"。

### 3.3 习惯修正(作用于真实年化收益,单位 pp)

| tradingHabit | 修正 | 不确定带 |
|---|---|---|
| indexOnly | 0 | ±0 |
| occasional | −0.5 | ±0.5 |
| weekly | −2.0 | ±1.5 |
| dayTrading | −4.0 | ±3.0 |

**账户规模放大**:under100k ×1.25,k100to500k ×1.0,k500to10m ×0.75,over10m ×0.5。
出处:上交所账户级研究 2016.1–2019.6,散户亏损 1.6%–20.5% 而机构盈利 11.22%,10 万元以下账户年均亏 2,457 元;An, Lou & Shi 2022:2014–15 年底部 85% 家庭亏损、顶部 0.5% 盈利,2500 亿元财富转移;Barber & Odean 2000(美国:高换手组年化跑输约 6–7pp)。中国参数优先。

**副业**:hasSideHustle 时收入 +10%,不确定带 ±10%。`TODO(calibrate)`,文献弱,报告里标"假设"。

### 3.4 素养修正

- literacyScore 3 → 真实收益 +0.25pp;0 → −0.25pp;1、2 → 0。出处:van Rooij, Lusardi & Alessie 2012(素养从 P25 到 P75 对应约 €80k 净资产差异,通道为股市参与与规划)。
- selfControl ≥ 5 → **仅悲观情景**储蓄率 −3pp。出处:同上论文,自控力是财富积累主要决定因素之一。
- 在报告里这两项的语气是"文献显示…的人平均…",不是"你会…"。

### 3.5 模拟算法

```
for scenario in [pessimistic, neutral, optimistic]:
  r  = realReturn(scenario) + tradingAdj*tierMultiplier + literacyAdj
  A  = investableAssets
  inc = monthlyIncome*12 * (1 + sideHustle ? 0.10 : 0)
  exp = monthlyExpense*12 * (scenario==pessimistic && selfControl>=5 ? 1.03 : 1)
  mort = mortgageMonthly*12, mortLeft = mortgageYearsLeft
  for age in profile.age ..< 100:
     freedomLine = exp * multiplier(scenario)        // 房贷还清后不计入自由线
     if A >= freedomLine and mortLeft == 0: return age
     savings = inc - exp - (mortLeft>0 ? mort : 0)
     A = A*(1+r) + savings
     growth = age < peakAge ? prePeakGrowth : postPeakGrowth
     inc *= (1+growth); exp *= (1+expenseGrowth); if mortLeft>0 { mortLeft -= 1 }
  return nil   // 100 岁前未达:UI 显示"未达 · 需提高储蓄率"
```

**归因(Attribution)**:以中性情景为基准,分别把 tradingHabit 设为 indexOnly、hasSideHustle 设为 false、literacyScore 设为 2、selfControl 设为 3 重跑,得到每个修正项的"年数差"。UI 上显示"炒股修正:推迟 2.3 年"这类文案。年数差保留一位小数(用月级插值)。

### 3.6 金标测试(必须先写,再写引擎)

收入/支出零增长、无房贷、无修正时,模拟结果须与闭式解一致(±1 年):

n = ln[(M(1−s) + s/r) ÷ (s/r + A/年收入)] ÷ ln(1+r)

| s | r | A | M | 期望 n |
|---|---|---|---|---|
| 0.50 | 0.05 | 0 | 25 | 16.6 |
| 0.25 | 0.05 | 0 | 25 | 31.9 |
| 0.28 | 0.05 | 0 | 25 | 29.5 |

另加:(a) 资产已超过自由线 → 当年即自由;(b) 储蓄为负 → 返回 nil;(c) 归因之和不必等于总差异,但每一项单独可复现;(d) `birthDate` 改变不改变任何输出(**这是产品原则的单测**)。

### 3.7 Lusardi 三大题(`Literacy.swift`)

题目用我们自己的措辞改写(原题为学术公用,但文案本地化):
1. 复利:100 元存入年利 2% 的账户,5 年后账户里比 102 元多/正好/少?
2. 通胀:年利 1%、通胀 2%,一年后能买到的东西比今天多/一样/少?
3. 分散:"买单只公司股票通常比买股票基金更安全"——对/错。
答对数即 literacyScore。答完立即显示对错与一句解释(这一屏本身有传播价值)。

---

## 4. 问卷(12 题,一屏一题,每答一题落一爻)

顺序与题型:
1. 年龄(滚轮)
2. 地区/币种(单选)
3. 税后月收入(数字,币种前缀)
4. 月支出,不含房贷(数字)
5. 可投资资产(数字;下方一行"不含自住房")
6. 房贷:月供 + 剩余年数(可跳过)
7. 行业(单选)+ 工作年限(滚轮)
8. 学历(单选)
9. 你炒股吗(单选,每项右侧显示修正年数)+ 账户规模(单选)
10. 副业(是/否)
11. 素养三题(三屏,即答即评)
12. 自控力 1–7(滑杆:"控制支出对你来说有多难")
13. (可选)出生日期——标题写明"仅用于汇票上的密押与配色,不参与计算"

进度指示:六爻线(前 6 题一爻一根,后 6 题第二组卦),见 `Hexagram.swift`。

---

## 5. 设计系统(以三份 HTML 设计稿为准)

设计稿在 `~/Design/`:`wealthclock_v2B_full.html`(四屏)、`wealthclock_sharecard_v3.html`(汇票)。**先在浏览器打开看,再写 UI。**

**色板** `Tokens.swift`:
```
paper   #EFE6D2   paper2 #E6DCC4
ink     #2B2622   inkSoft #6B625A
cinnabar#B8412F   (只给:红栏线、印章、密押行、修正项红字)
gilt    #C6A14A   giltDeep #9A7A2E (只给:大数字、铜钱、自由线数值)
verdigris #5E7D6A (悲观曲线、次要数据)
```
**字体**:汉字 `.fontDesign(.serif)`(New York → 中文回落宋体);数据 `.monospaced`;汇票大字用 **Ma Shan Zheng**(OFL)。字体文件从 google/fonts 仓库 `ofl/mashanzheng/MaShanZheng-Regular.ttf` 下载,放 `Resources/Fonts/`,加进 `UIAppFonts`。License 文件一并放入并在设置页"开源许可"里展示。
**像素**:只在大数字(5×7 点阵)和铜钱(11×11)出现,用 `Canvas` 画矩形,不用字体。
**花边**:`Guilloche.swift` 按 sharecard_v3.html 里的方程实现——角饰:r(θ)=R(0.62+0.16sin(6θ+φ)+0.09sin(11θ−2φ)+0.05sin(17θ+3φ)),10 层 φ 递增 0.31;边带:7 条 sin 交织线。参数写死,保证每次一致。
**动效只有一个**:揭晓页掷钱六次(180ms/次,随机阴阳面)→ 数字 1.3s ease-out 滚动到结果。`accessibilityReduceMotion` 为真时直接显示。

---

## 6. 各页面验收标准

**Reveal(揭晓)**:eyebrow"你的财务自由年龄"→ 点阵大数字 → "岁" → 苏州码子行(〡〢〣〤〥〦〧〨〩 映射)→ 三枚铜钱 + 六爻 → 三情景 chip → 密押行(朱砂)→ 主按钮"查看完整推演"、次按钮"保存汇票"。**未购买用户也能看到三情景数字**,这是产品原则。
**Bill(汇票)**:按 sharecard_v3 实现,`ImageRenderer.scale = 3`,输出 1080×1920 PNG;`ShareLink`;色系按出生日期年份天干映射五行(木=铜绿,火=朱砂,土=鎏金底,金=墨,水=藏青),没有出生日期则朱砂。密押句从一个本地词库随机(30 句,语气温和、不预言、不吓人;文案我来审)。
**Scenarios(推演,付费)**:Swift Charts 三条 LineMark + RuleMark 自由线 + PointMark 用像素铜钱做 symbol;账目四行;归因列表(每项一行,附"依据:…"可展开);脚注"情景测算,非投资建议;密押为传统文化趣味解读,不参与计算"。
**History**:SwiftData 保存每次测算(输入快照 + 三情景结果 + 归因 + 日期)。列表 + 详情。**免费**。设置页提供导出 JSON/CSV 与"删除全部数据"。
**Paywall**:一次性买断,产品 ID `app.wealthclock.report.full`,非消耗型。文案:"三情景结果与汇票永远免费。完整推演(曲线、归因、年度对比)买断一次,永久可用。" 有"恢复购买"。价格我在 App Store Connect 定,代码里不硬编码。
**Settings**:隐私政策链接、支持链接、恢复购买、导出数据、删除数据、开源许可(字体)、版本号。

---

## 7. 合规硬要求

- 无网络请求(v1 完全离线),无账号,无分析。`PrivacyInfo.xcprivacy` 声明 UserDefaults 访问理由(CA92.1)。
- `Info.plist`:`ITSAppUsesNonExemptEncryption = NO`。
- 三处免责声明(揭晓页脚、推演页脚、付费墙):"本应用提供的是基于公开文献的情景测算与传统文化趣味解读,不构成投资、财务或法律建议。"
- 语气规范(写进密押词库与文案):不预言、不制造恐惧、归因指向用户自己的行为而非"命"。
- 本地化:zh-Hans(默认)、zh-Hant、en,用 String Catalog。汇票上的繁体是设计元素,不随系统语言变。

---

## 8. 里程碑(每个结束→测试通过→commit→汇报→等确认)

- **M0 脚手架**:目录结构、Tokens、字体接入、String Catalog、空导航。验收:能跑,显示一张宣纸色空页。
- **M1 引擎**:先写 §3.6 金标测试,再写引擎到测试全绿。验收:`swift test` 绿;打印一份示例 Profile 的三情景 + 归因。
- **M2 设计组件**:PixelDigits、PixelCoin、Guilloche、Hexagram 四个组件 + 一个 Preview 画廊页(Debug 用)。验收:和 HTML 稿肉眼一致。
- **M3 揭晓页**:含掷钱动效,先用硬编码 Profile。验收:动效流畅,reduceMotion 生效。
- **M4 汇票**:BillView + ImageRenderer 导出 + ShareLink + 五行配色。验收:导出 PNG 在照片 App 里清晰。
- **M5 问卷**:12 题 + 六爻进度 + 输入校验 + Literacy 即答即评 → 接引擎 → 揭晓。验收:完整走通一次。
- **M6 持久化 + 历史 + 设置**:SwiftData、导出、删除、开源许可页。
- **M7 付费墙 + 推演页**:StoreKit 2、`.storekit` 本地配置文件测试、恢复购买、推演页。验收:模拟器上购买→解锁→重装→恢复成功。
- **M8 上架准备**:App 图标(用 Guilloche + 铜钱程序生成 1024 PNG)、模拟器截图脚本(6.9" 与 6.5" 各 5 张)、`metadata/` 目录(名称、副标题、关键词 100 字、描述、隐私政策 markdown、支持页 markdown、审核备注)。

---

## 9. 审核备注草稿(M8 产出,给 App Review 看)

> WealthClock calculates a "financial freedom age" from user-entered income, expenses, assets and habits, using published research (safe-withdrawal-rate studies; age-earnings profiles; retail-investor trading studies; financial-literacy studies). All calculations run on-device; no account, no network, no data collection. The "omen" line and colour on the shareable card are traditional-culture flavour text and are explicitly labelled as not affecting any calculation. The one-time in-app purchase unlocks the detailed scenario report; core results and the share card are free. The app is not available in mainland China.

---

## 10. 明确不做的事(v1)

订阅制、账号系统、云同步、推送通知、社交功能、AI 生成解读、任何联网、中国大陆商店上架、Android。
