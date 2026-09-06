---
name: wealthclock-design-system
description: WealthClock 的视觉系统——宣纸/拓印墨/朱砂/鎏金/铜绿色板,New York+SF Mono+OFL 毛笔字,像素只给大数字与铜钱、古籍版式给其余,朱砂只给玄学层。写任何 SwiftUI View、改任何颜色字体间距、做汇票/揭晓/推演/问卷页面、生成图标或截图之前必须读本技能;用户说"改一下样式""好看一点""换个颜色"时也要用。
---

# WealthClock Design System

设计稿是真源:`docs/design/screens_v2B.html`(问卷/揭晓/推演/汇票)与 `docs/design/sharecard_v3.html`(雕版单色汇票)。**先在浏览器打开看,再写代码。** 颜色/字体细节见 `references/tokens.md`。

## 三条分工铁律(违反即返工)
1. **像素只出现在两处**:大数字(5×7 点阵,Canvas 画)与铜钱(11×11)。其余一切是古籍/汇票版式。
2. **朱砂只给玄学层与警示**:红栏线、印章、密押行、归因里的"推迟 N 年"。算术层用墨/鎏金/铜绿。
3. **鎏金只给"钱落下的地方"**:大数字、铜钱、自由线数值、曲线交点。不给按钮,不给背景。

## 字体
- 汉字标题/正文:`.fontDesign(.serif)`(New York;中文回落宋体)。
- 数据、轴、金额:`.monospaced`。
- 汇票大字"自由":`MaShanZheng-Regular`(OFL,已打包)。
- 苏州码子用 `Suzhou.string(from:)`,中文大写用 `Suzhou.chineseUpper(_:)`。

## 动效
只有一个:揭晓页掷钱六次(180ms/次)→ 数字 1.3s ease-out 滚动。`accessibilityReduceMotion` 为真则直接显示。其他页面零动效。

## 组件
`Design/PixelDigits.swift`、`Design/PixelCoin.swift`、`Design/Guilloche.swift`、`Design/Hexagram.swift`。花边方程见 tokens.md,参数写死,每次渲染必须一致。

## 自检(写完 View 后逐条问)
- 这一屏有没有出现第二种动效?
- 朱砂是否出现在了算术层?
- 像素是否出现在了数字和铜钱以外?
- 截图和设计稿并排看,能不能一眼分辨是同一套?
