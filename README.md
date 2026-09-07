本仓库公开期间不含密押词库与营销文案。

# WealthClock

用数学算命:算出你的财务自由年龄(三情景),以掷铜钱→点阵数字的仪式揭晓,生成雕版钞票风格的"汇票"结果卡。
命理只做包装,永远不参与计算。

- 智能体作业手册:`AGENTS.md`
- 产品与工程规格:`docs/BRIEF.md`
- 上架清单:`docs/APPSTORE_CHECKLIST.md`
- 设计稿:`docs/design/`(浏览器打开)
- 研究依据:`docs/research/`

## 开发
```bash
brew install xcodegen swiftlint swiftformat
xcodegen generate
open WealthClock.xcodeproj
scripts/verify.sh
```
