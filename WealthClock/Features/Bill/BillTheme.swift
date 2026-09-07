import SwiftUI

/// 汇票单色系列(sharecard_v3.html data-hue/paper/tint;tokens.md 五行→色系)。
/// 印章永远朱砂,不随主色走。
struct BillTheme: Equatable {
    let name: String
    let hue: Color
    let paper: Color
    let tint: Color

    static let cinnabar = BillTheme(name: "朱砂", hue: Color(hex: 0xB8412F), paper: Color(hex: 0xF3E9E1), tint: Color(hex: 0xE9D7CE))
    static let verdigris = BillTheme(name: "铜绿", hue: Color(hex: 0x4F7C63), paper: Color(hex: 0xE9EFE5), tint: Color(hex: 0xD6E2D2))
    static let indigo = BillTheme(name: "藏青", hue: Color(hex: 0x35507A), paper: Color(hex: 0xE7EBF1), tint: Color(hex: 0xD3DBE7))
    // 土/金两系设计稿未给 paper/tint,按同明度推得,待人类目视验收调整。
    static let gilt = BillTheme(name: "鎏金", hue: Color(hex: 0x9A7A2E), paper: Color(hex: 0xF2EBD8), tint: Color(hex: 0xE6DCC0))
    static let ink = BillTheme(name: "墨", hue: Color(hex: 0x2B2622), paper: Color(hex: 0xEFE6D2), tint: Color(hex: 0xE0D8C6))

    /// 出生年天干 → 五行 → 色系(木=铜绿 火=朱砂 土=鎏金 金=墨 水=藏青)。
    /// 无出生日期 = 朱砂。仅视觉,永不参与计算(AGENTS §7.6)。
    static func forBirthDate(_ date: Date?) -> BillTheme {
        guard let date else { return .cinnabar }
        let year = Calendar(identifier: .gregorian).component(.year, from: date)
        let stem = ((year - 4) % 10 + 10) % 10  // 0甲1乙…9癸
        switch stem / 2 {
        case 0: return .verdigris  // 甲乙 木
        case 1: return .cinnabar   // 丙丁 火
        case 2: return .gilt       // 戊己 土
        case 3: return .ink        // 庚辛 金
        default: return .indigo    // 壬癸 水
        }
    }
}
