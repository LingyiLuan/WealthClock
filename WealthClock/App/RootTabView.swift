import FreedomEngine
import SwiftData
import SwiftUI

/// 根导航:测算 / 历史 / 设置(BRIEF §6;M6 统一为 TabView)。
struct RootTabView: View {
    enum Tab {
        case quiz, history, settings
    }

    @Environment(\.modelContext) private var modelContext
    @State private var tab: Tab

    init(initialTab: Tab = .quiz) {
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $tab) {
            QuizView()
                .tabItem { Label("测算", systemImage: "circle.grid.cross") }
                .tag(Tab.quiz)
            HistoryView()
                .tabItem { Label("历史", systemImage: "clock") }
                .tag(Tab.history)
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .tint(Tokens.giltDeep)
        .task { seedIfRequested() }
    }

    /// DEBUG:-seedSample 在库为空时插入一条示例存档(供人类验收历史页,免手答 12 题)。
    private func seedIfRequested() {
        #if DEBUG
        guard CommandLine.arguments.contains("-seedSample") else { return }
        let existing = (try? modelContext.fetchCount(FetchDescriptor<Reading>())) ?? 0
        guard existing == 0 else { return }
        modelContext.insert(Reading(profile: .sample, result: FreedomEngine.run(.sample)))
        #endif
    }
}
