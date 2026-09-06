import SwiftUI
import FreedomEngine

/// M0 占位页:一张宣纸色空页 + 引擎冒烟输出。M3 起替换为 Reveal。
struct ContentView: View {
    private let sample = FreedomEngine.run(Profile.sample)

    var body: some View {
        ZStack {
            Color(red: 0xEF / 255, green: 0xE6 / 255, blue: 0xD2 / 255).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("WealthClock").font(.system(.title, design: .serif))
                if let neutral = sample.scenario(.neutral), let age = neutral.freedomAge {
                    Text("示例中性情景:\(Int(age.rounded())) 岁")
                        .font(.system(.body, design: .monospaced))
                } else {
                    Text("示例:100 岁前未达").font(.system(.body, design: .monospaced))
                }
            }
            .foregroundStyle(Color(red: 0x2B / 255, green: 0x26 / 255, blue: 0x22 / 255))
        }
    }
}

#Preview { ContentView() }
