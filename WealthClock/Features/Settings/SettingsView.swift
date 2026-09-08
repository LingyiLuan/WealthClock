import FreedomEngine
import SwiftData
import SwiftUI

/// 设置(BRIEF §6):链接、导出、删除、开源许可、版本。数据永远免费可看/可导出/可删除。
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var readings: [Reading]
    @State private var confirmDelete = false

    private let privacyURL = URL(string: "https://wealthclock.app/privacy")   // TODO: 上架前替换正式地址
    private let supportURL = URL(string: "https://wealthclock.app/support")   // TODO: 上架前替换正式地址

    var body: some View {
        NavigationStack {
            List {
                Section("链接") {
                    if let privacyURL { Link("隐私政策", destination: privacyURL) }
                    if let supportURL { Link("支持", destination: supportURL) }
                }
                Section("数据") {
                    if let url = exportFile(ext: "json", content: exportJSON()) {
                        ShareLink(item: url) { Text("导出 JSON") }
                    }
                    if let url = exportFile(ext: "csv", content: exportCSV()) {
                        ShareLink(item: url) { Text("导出 CSV") }
                    }
                    Button("删除全部数据", role: .destructive) { confirmDelete = true }
                }
                Section("关于") {
                    NavigationLink("开源许可") { LicenseView() }
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(verbatim: version).foregroundStyle(Tokens.inkSoft)
                    }
                }
                Section {
                } footer: {
                    Text("本应用提供的是基于公开文献的情景测算与传统文化趣味解读,不构成投资、财务或法律建议。所有数据仅保存在本机,应用不联网。")
                        .font(.system(size: 11, design: .serif))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Tokens.paper.ignoresSafeArea())
            .navigationTitle("设置")
            .confirmationDialog("删除全部测算记录?此操作不可撤销。", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("删除全部", role: .destructive) { try? modelContext.delete(model: Reading.self) }
                Button("取消", role: .cancel) {}
            }
        }
        .tint(Tokens.giltDeep)
    }

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    // MARK: 导出

    private struct ExportItem: Codable {
        let date: Date
        let profile: Profile?
        let result: ReadingResultDTO?
        let omen: String
    }

    private func exportJSON() -> String {
        let items = readings.map { ExportItem(date: $0.date, profile: $0.profile, result: $0.result, omen: $0.omenPhrase) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return String(data: (try? encoder.encode(items)) ?? Data(), encoding: .utf8) ?? "[]"
    }

    private func exportCSV() -> String {
        var lines = ["date,age,region,monthlyIncome,monthlyExpense,investableAssets,tradingHabit,neutralAge,optimisticAge,pessimisticAge,omen"]
        let iso = ISO8601DateFormatter()
        for reading in readings {
            let profile = reading.profile
            let result = reading.result
            func num(_ value: Double?) -> String { value.map { String(format: "%.1f", $0) } ?? "" }
            lines.append([
                iso.string(from: reading.date),
                profile.map { String($0.age) } ?? "",
                profile?.region.rawValue ?? "",
                profile.map { String(format: "%.0f", $0.monthlyIncome) } ?? "",
                profile.map { String(format: "%.0f", $0.monthlyExpense) } ?? "",
                profile.map { String(format: "%.0f", $0.investableAssets) } ?? "",
                profile?.tradingHabit.rawValue ?? "",
                num(result?.age(.neutral)),
                num(result?.age(.optimistic)),
                num(result?.age(.pessimistic)),
                reading.omenPhrase
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private func exportFile(ext: String, content: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("WealthClock-readings.\(ext)")
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

/// 开源许可:Ma Shan Zheng(SIL OFL 1.1,全文来自打包的 OFL.txt)。
struct LicenseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ma Shan Zheng · SIL Open Font License 1.1")
                    .font(.system(size: 14, design: .serif).weight(.medium))
                    .foregroundStyle(Tokens.ink)
                Text(verbatim: licenseText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Tokens.inkSoft)
            }
            .padding(Tokens.pageMargin)
        }
        .background(Tokens.paper.ignoresSafeArea())
        .navigationTitle("开源许可")
    }

    private var licenseText: String {
        guard let url = Bundle.main.url(forResource: "OFL", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return "OFL.txt 未找到" }
        return text
    }
}
