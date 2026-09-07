import SwiftUI

/// 色板与间距唯一来源:`.claude/skills/wealthclock-design-system/references/tokens.md`。
/// 改任何颜色/间距先改 tokens.md,再同步这里。
enum Tokens {
    // 色板
    static let paper = Color(hex: 0xEFE6D2)      // 页面底
    static let paper2 = Color(hex: 0xE6DCC4)     // 汇票底
    static let ink = Color(hex: 0x2B2622)        // 文字、点阵、阴面铜钱
    static let inkSoft = Color(hex: 0x6B625A)    // 次要文字
    static let cinnabar = Color(hex: 0xB8412F)   // 红栏线、印章、密押行、警示数字
    static let gilt = Color(hex: 0xC6A14A)       // 铜钱、大数字高亮
    static let giltDeep = Color(hex: 0x9A7A2E)   // 铜钱边、鎏金文字
    static let verdigris = Color(hex: 0x5E7D6A)  // 悲观曲线、次要数据
    static let rule = Color(hex: 0xB8412F).opacity(0.33)  // 账簿栏线

    // 间距
    static let pageMargin: CGFloat = 24
    static let cardPadding: CGFloat = 22
    static let ledgerRowHeight: CGFloat = 44
    static let primaryButtonHeight: CGFloat = 50
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
