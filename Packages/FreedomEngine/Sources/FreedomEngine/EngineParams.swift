import Foundation

/// 全部可校准参数集中在此。改任何数字 = L0 级 PR(AGENTS.md §4.1),并同步更新 docs/research/science-basis.md。
public enum EngineParams {
    public static let maxAge = 100

    /// 出处:
    /// - 提取率:Bengen 1994;Trinity 1998;Morningstar 2025 (3.7%);Bengen 2024 上调至 4.7%;40 年以上期限研究建议 3.25–3.5%。
    /// - 收入峰值年龄:Fang & Qiu, "Golden Ages", JPE 2023 —— 中国横截面峰值年龄已从 55 降至 35;美国稳定在 45–50。
    /// - 收入/支出增速:Mincer 1974 凹型曲线;具体数值 TODO(calibrate)。
    public static func scenario(_ kind: ScenarioKind) -> ScenarioParams {
        switch kind {
        case .pessimistic:
            return ScenarioParams(withdrawalRate: 0.035, realReturn: 0.03, prePeakGrowth: 0.02, postPeakGrowth: -0.01, expenseGrowth: 0.01, peakAgeCN: 35, peakAgeOther: 45)
        case .neutral:
            return ScenarioParams(withdrawalRate: 0.040, realReturn: 0.05, prePeakGrowth: 0.03, postPeakGrowth: 0.00, expenseGrowth: 0.00, peakAgeCN: 40, peakAgeOther: 50)
        case .optimistic:
            return ScenarioParams(withdrawalRate: 0.047, realReturn: 0.07, prePeakGrowth: 0.04, postPeakGrowth: 0.00, expenseGrowth: 0.00, peakAgeCN: 45, peakAgeOther: 50)
        }
    }

    /// 出处:Mincer 教育回报。数值 TODO(calibrate)。
    public static func educationGrowthAdjustment(_ education: Education) -> Double {
        switch education {
        case .belowBachelor: return -0.005
        case .bachelor: return 0.0
        case .masterPlus: return 0.005
        }
    }

    /// 行业对峰值年龄的修正(岁)。TODO(calibrate):接入国家统计局分行业工资曲线后替换。
    public static func industryPeakAdjustment(_ industry: Industry, region: Region) -> Int {
        switch industry {
        case .tech: return region == .cnMainland ? -5 : -3
        case .government, .healthcare, .education: return 5
        default: return 0
        }
    }

    /// 出处:上交所账户级研究 2016.1–2019.6(散户亏损 1.6%–20.5%,机构 +11.22%);An, Lou & Shi 2022;Barber & Odean 2000。
    /// 返回 (真实收益修正 pp, 不确定带 pp)。
    public static func tradingAdjustment(_ habit: TradingHabit) -> (delta: Double, band: Double) {
        switch habit {
        case .indexOnly: return (0.0, 0.0)
        case .occasional: return (-0.005, 0.005)
        case .weekly: return (-0.020, 0.015)
        case .dayTrading: return (-0.040, 0.030)
        }
    }

    /// 账户规模放大系数。出处:上交所研究显示小账户亏损率更高。
    public static func tierMultiplier(_ tier: AccountTier) -> Double {
        switch tier {
        case .under100k: return 1.25
        case .k100to500k: return 1.0
        case .k500to10m: return 0.75
        case .over10m: return 0.5
        }
    }

    /// 出处:van Rooij, Lusardi & Alessie 2012(素养 P25→P75 对应约 €80k 净资产差异)。数值 TODO(calibrate)。
    public static func literacyAdjustment(_ score: Int) -> Double {
        switch score {
        case 3: return 0.0025
        case 0: return -0.0025
        default: return 0.0
        }
    }

    /// 副业收入上修。文献弱,报告里标"假设"。TODO(calibrate)。
    public static let sideHustleUplift = 0.10

    /// 自控力差 → 仅悲观情景支出 +3%。出处:van Rooij et al. 2012 自控力与财富积累。
    public static let selfControlThreshold = 5
    public static let selfControlExpenseFactor = 1.03

    /// 报告用的依据短句。
    public enum Basis {
        public static let trading = "上交所 2016–2019 账户数据;An, Lou & Shi 2022;Barber & Odean 2000"
        public static let sideHustle = "假设:副业收入 +10%,文献证据弱"
        public static let literacy = "van Rooij, Lusardi & Alessie 2012"
        public static let selfControl = "van Rooij, Lusardi & Alessie 2012(自控力)"
    }
}
