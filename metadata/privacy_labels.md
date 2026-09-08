# App Store 隐私标签填写说明

App Store Connect → App Privacy → 选择 **Data Not Collected(不收集数据)**。

依据(逐项核对):
- 无网络请求:代码零联网(SwiftLint 自定义规则 `no_networking` 机械守护),无服务器、无账号。
- 无第三方 SDK:不接分析、广告、崩溃上报(AGENTS.md §7.1)。
- 用户输入(收入/支出/资产/出生日期等)仅存本机 SwiftData,开发者不可见,不属于"收集"(Apple 定义:数据须离开设备并可被开发者或合作方访问才算收集)。
- IAP 由 Apple StoreKit 处理,开发者不接触支付信息。
- `PrivacyInfo.xcprivacy` 已声明:NSPrivacyTracking = false;收集类型为空;Accessed API 仅 UserDefaults(理由 CA92.1,应用自身偏好)。

因此三类问题(是否收集数据 / 是否追踪 / 数据是否关联身份)全部为否。
