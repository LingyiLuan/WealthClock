# ADR-0001: 技术栈

- 状态:accepted
- 日期:2026-09-02
- 触发:项目初始化

## 问题
单人 + 多智能体开发一个离线 iOS 付费 App,要求逻辑可移植到 H5,项目文件对智能体友好。

## 选项
A. SwiftUI + 手工 .xcodeproj
B. SwiftUI + XcodeGen(project.yml)+ 引擎独立 Swift Package
C. React Native / Flutter

## 议会
### 产品经理
判断:B。首发只有 iOS,不需要跨平台;引擎独立能给 H5 版复用。
证据来源:docs/research/reviews-findings.md——"闪退/卡顿"占低分 9.1%,原生减少这类风险;付费主力在海外 iOS。
对其他角色的回应:同意全栈提出的 golden.json 语言无关设计。

### UI 设计师
判断:B。像素与花边都是程序生成,SwiftUI Canvas/Path 足够;不需要第三方 UI 库。
证据来源:docs/design/sharecard_v3.html 的花边完全是参数方程。
对其他角色的回应:接受 iOS 工程师关于竖排文字需手工实现的成本。

### iOS 工程师
判断:B。pbxproj 是智能体并行工作的冲突源,XcodeGen 把它变成可读可 diff 的 YAML;SwiftData/StoreKit 2/Swift Charts 覆盖全部需求,iOS 17 起点合理。
证据来源:Apple 文档(SwiftData iOS 17+、ImageRenderer iOS 16+、Swift Charts iOS 16+、StoreKit 2 iOS 15+)。
对其他角色的回应:否决 C——RN/Flutter 的 StoreKit 与 ImageRenderer 桥接会成为审核与质量风险。

### 全栈工程师
判断:B,附加要求:引擎只依赖 Foundation,金标固件用 JSON,便于未来 TypeScript 引擎跑同一套固件。
证据来源:golden.json 已按语言无关格式写。
对其他角色的回应:同意。

## 结论
选择:B。
理由:智能体友好(文本项目文件、纯逻辑包、独立评测集)+ 平台原生质量 + 逻辑可移植。

## 后果
- 要做:project.yml 是唯一真源;.xcodeproj 进 .gitignore。
- 不做:任何跨平台层;v1 任何联网。
- 回滚条件:若 XcodeGen 无法表达某个必需的 Xcode 配置,退回 A 并记录。
