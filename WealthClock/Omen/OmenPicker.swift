import Foundation
import FreedomEngine

/// 密押词条(Resources/OmenLexicon.json,30 条,文案由人类审定)。
struct OmenEntry: Decodable, Equatable {
    let phrase: String
    let gloss: String
}

private final class OmenBundleToken {}

/// 密押层(Omen):只产出文案与配色线索,永不参与任何计算(AGENTS §7.6)。
enum OmenPicker {
    static let entries: [OmenEntry] = {
        guard let url = Bundle(for: OmenBundleToken.self).url(forResource: "OmenLexicon", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lexicon = try? JSONDecoder().decode(Lexicon.self, from: data)
        else { return [OmenEntry(phrase: "待定", gloss: "词库加载失败")] }
        return lexicon.entries
    }()

    private struct Lexicon: Decodable {
        let entries: [OmenEntry]
    }

    /// 当前年份天干地支,如 "丙午"。
    static func yearGanzhi(for date: Date = .now) -> String {
        let year = Calendar(identifier: .gregorian).component(.year, from: date)
        let stems = Array("甲乙丙丁戊己庚辛壬癸")
        let branches = Array("子丑寅卯辰巳午未申酉戌亥")
        let offset = ((year - 4) % 60 + 60) % 60
        return String(stems[offset % 10]) + String(branches[offset % 12])
    }

    /// 用 Profile 的稳定哈希做种子抽一条:同一次测算复看不变(跨启动、跨设备一致)。
    static func pick(for profile: Profile) -> OmenEntry {
        entries[Int(stableHash(profile) % UInt64(max(entries.count, 1)))]
    }

    /// FNV-1a over 排序键 JSON——不用 Swift hashValue(跨启动不稳定)。
    static func stableHash(_ profile: Profile) -> UInt64 {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = (try? encoder.encode(profile)) ?? Data()
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in data {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }
}
