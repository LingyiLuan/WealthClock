import Foundation

/// 苏州码子:〇〡〢〣〤〥〦〧〨〩。用于汇票与揭晓页的副写法。
public enum Suzhou {
    private static let glyphs: [Character] = ["〇", "〡", "〢", "〣", "〤", "〥", "〦", "〧", "〨", "〩"]

    public static func string(from value: Int) -> String {
        let digits = String(max(value, 0))
        return String(digits.compactMap { ch -> Character? in
            guard let d = ch.wholeNumberValue, d >= 0, d <= 9 else { return nil }
            return glyphs[d]
        })
    }

    private static let lower: [Character] = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]

    /// 铭文读法(0–99):20–29 用"廿"、30–39 用"卅",其余"三十五"写法(汇票竖排铭文用)。
    public static func inscription(_ value: Int) -> String {
        let v = min(max(value, 0), 99)
        if v < 10 { return String(lower[v]) }
        let tens = v / 10, ones = v % 10
        let onesPart = ones == 0 ? "" : String(lower[ones])
        switch tens {
        case 1: return "十" + onesPart
        case 2: return "廿" + onesPart
        case 3: return "卅" + onesPart
        default: return String(lower[tens]) + "十" + onesPart
        }
    }

    private static let upper: [Character] = ["零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖"]

    /// 简化的中文大写(仅 0–99,足够表示年龄)。
    public static func chineseUpper(_ value: Int) -> String {
        let v = min(max(value, 0), 99)
        if v < 10 { return String(upper[v]) }
        let tens = v / 10, ones = v % 10
        let tensPart = tens == 1 ? "拾" : "\(upper[tens])拾"
        return ones == 0 ? tensPart : tensPart + String(upper[ones])
    }
}
