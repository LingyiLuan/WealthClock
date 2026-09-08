import Foundation
import FreedomEngine

/// 年度对比(付费,BRIEF §6 推演"年度对比"):当前记录 vs 最早一条相隔 ≥300 天的记录。
struct YearComparison {
    static let minimumDaysApart = 300

    let daysApart: Int
    let previousAge: Double?
    let currentAge: Double?
    let previousSavingsRate: Int
    let currentSavingsRate: Int
    let previousAssets: Double
    let currentAssets: Double

    /// 自由年龄变化:负 = 提前(铜绿),正 = 推迟(朱砂);任一侧未达 → nil。
    var ageDelta: Double? {
        guard let previousAge, let currentAge else { return nil }
        return ((currentAge - previousAge) * 10).rounded() / 10
    }

    static func make(current: Reading, among readings: [Reading]) -> YearComparison? {
        let candidates = readings
            .filter { $0.persistentModelID != current.persistentModelID && $0.date < current.date }
            .sorted { $0.date < $1.date }
        guard let previous = candidates.first(where: {
            daysBetween($0.date, current.date) >= minimumDaysApart
        }) else { return nil }
        guard let previousProfile = previous.profile, let currentProfile = current.profile else { return nil }
        return YearComparison(
            daysApart: daysBetween(previous.date, current.date),
            previousAge: previous.result?.age(.neutral),
            currentAge: current.result?.age(.neutral),
            previousSavingsRate: savingsRate(previousProfile),
            currentSavingsRate: savingsRate(currentProfile),
            previousAssets: previousProfile.investableAssets,
            currentAssets: currentProfile.investableAssets
        )
    }

    private static func daysBetween(_ from: Date, _ to: Date) -> Int {
        Int(to.timeIntervalSince(from) / 86_400)
    }

    private static func savingsRate(_ profile: Profile) -> Int {
        guard profile.monthlyIncome > 0 else { return 0 }
        return Int(((1 - profile.monthlyExpense / profile.monthlyIncome) * 100).rounded())
    }
}
