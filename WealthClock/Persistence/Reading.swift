import Foundation
import FreedomEngine
import SwiftData

/// 一次测算的存档(BRIEF §6 History:输入快照 + 三情景结果 + 归因 + 日期;历史永远免费)。
@Model
final class Reading {
    var date: Date
    var profileJSON: Data
    var resultJSON: Data
    var omenPhrase: String
    var omenGloss: String
    var ganzhi: String

    init(profile: Profile, result: FreedomResult, date: Date = .now) {
        self.date = date
        profileJSON = (try? JSONEncoder().encode(profile)) ?? Data()
        resultJSON = (try? JSONEncoder().encode(ReadingResultDTO(result))) ?? Data()
        let omen = OmenPicker.pick(for: profile)
        omenPhrase = omen.phrase
        omenGloss = omen.gloss
        ganzhi = OmenPicker.yearGanzhi(for: date)
    }

    var profile: Profile? {
        try? JSONDecoder().decode(Profile.self, from: profileJSON)
    }

    var result: ReadingResultDTO? {
        try? JSONDecoder().decode(ReadingResultDTO.self, from: resultJSON)
    }
}

/// 结果快照 DTO(引擎类型不声明 Codable,存档结构与引擎解耦,H5 版可读同一 JSON)。
struct ReadingResultDTO: Codable {
    struct Scenario: Codable {
        let kind: String
        let freedomAge: Double?
        let freedomLine: Double
    }

    struct AttributionItem: Codable {
        let key: String
        let deltaYears: Double?
        let basis: String
    }

    let scenarios: [Scenario]
    let attributions: [AttributionItem]

    init(_ result: FreedomResult) {
        scenarios = result.scenarios.map {
            Scenario(kind: $0.kind.rawValue, freedomAge: $0.freedomAge, freedomLine: $0.freedomLine)
        }
        attributions = result.attributions.map {
            AttributionItem(key: $0.key, deltaYears: $0.deltaYears, basis: $0.basis)
        }
    }

    func age(_ kind: ScenarioKind) -> Double? {
        scenarios.first { $0.kind == kind.rawValue }?.freedomAge
    }
}
