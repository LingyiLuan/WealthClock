import FreedomEngine
import SwiftUI

/// 汇票结果卡(BRIEF §6 Bill,sharecard_v3.html 逐坐标复刻)。
/// 设计坐标系 360×640;ImageRenderer scale 3 → 1080×1920(M4 第二个 PR 接导出)。
struct BillView: View {
    let profile: Profile
    let theme: BillTheme
    private let result: FreedomResult

    // 设计稿框架常量(sharecard_v3.html buildCard)
    private static let frame = (x: 44.0, y: 104.0, w: 272.0, h: 432.0, bw: 14.0)
    private static let sealColor = Color(hex: 0xB8412F)  // 印章永远朱砂

    init(profile: Profile = .sample) {
        self.profile = profile
        theme = BillTheme.forBirthDate(profile.birthDate)
        result = FreedomEngine.run(profile)
    }

    private var age: Int? { result.scenario(.neutral)?.freedomAge.map { Int($0.rounded()) } }

    private func trad(_ value: Int?) -> String {
        guard let value else { return "未達" }
        let digits: [Character] = ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
        return String(String(value).compactMap { $0.wholeNumberValue.map { digits[$0] } })
    }

    private var ageWords: String {
        guard let age else { return "NOT YET" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "en_US")
        return (formatter.string(from: NSNumber(value: age)) ?? String(age)).uppercased()
    }

    var body: some View {
        let f = Self.frame
        ZStack {
            theme.paper
            engraving
            arcText("FINANCIALLY FREE AT \(ageWords)", center: CGPoint(x: 180, y: 300), radius: 236, degrees: (-125, -55), flip: false)
            arcText("THE MATH IS THE BLESSING", center: CGPoint(x: 180, y: 340), radius: 236, degrees: (125, 55), flip: true)
            sideBlessing(x: 24, angle: -90)
            sideBlessing(x: 336, angle: 90)
            pixelCorner(x: f.x + f.bw + 22, y: f.y + f.bw + 22)
            pixelCorner(x: f.x + f.w - f.bw - 22 - 26.4, y: f.y + f.h - f.bw - 22 - 16.8)
            serif("SUI · 歲", size: 6.5, kerning: 1.6)
                .position(x: f.x + f.bw + 22 + 20, y: f.y + f.bw + 22 + 16.8 + 8)
            header
            bigCharacters
            verticalMotto("用數學算命", x: f.x + f.bw + 30, y: f.y + f.h / 2 - 30)
            verticalMotto("儲蓄率\(trad(savingsRatePercent))", x: f.x + f.w - f.bw - 30, y: f.y + f.h / 2 + 10)
            serif("\(Suzhou.chineseUpper(age ?? 0))歲 · 樂觀\(trad(scenarioAge(.optimistic))) · 悲觀\(trad(scenarioAge(.pessimistic)))", size: 10, kerning: 3)
                .position(x: 180, y: f.y + f.h - f.bw - 30)
            seals
            footer
        }
        .frame(width: 360, height: 640)
    }

    private var savingsRatePercent: Int {
        guard profile.monthlyIncome > 0 else { return 0 }
        return Int(((1 - profile.monthlyExpense / profile.monthlyIncome) * 100).rounded())
    }

    private func scenarioAge(_ kind: ScenarioKind) -> Int? {
        result.scenario(kind)?.freedomAge.map { Int($0.rounded()) }
    }

    /// 花边层:四条边带 + 四角玫瑰 + 双细框 + 底纹 + 内芯纸面(全部 Canvas 矢量)。
    private var engraving: some View {
        let f = Self.frame
        return Canvas { context, _ in
            for band in [(f.x + 24, f.y, false), (f.x + 24, f.y + f.h - f.bw, false), (f.x, f.y + 24, true), (f.x + f.w - f.bw, f.y + 24, true)] {
                var layer = context
                layer.translateBy(x: band.0, y: band.1)
                if band.2 { layer.rotate(by: .degrees(90)); layer.translateBy(x: 0, y: -f.bw) }
                let length = band.2 ? f.h - 48 : f.w - 48
                layer.stroke(Guilloche.edgeBandPath(length: length, bandWidth: f.bw), with: .color(theme.hue.opacity(0.85)), lineWidth: 0.5)
            }
            for (index, corner) in [(f.x, f.y), (f.x + f.w, f.y), (f.x, f.y + f.h), (f.x + f.w, f.y + f.h)].enumerated() {
                let center = CGPoint(x: corner.0, y: corner.1)
                context.stroke(Guilloche.cornerPath(radius: 26, center: center, seed: 0.2 + Double(index) * 1.2), with: .color(theme.hue.opacity(0.9)), lineWidth: 0.55)
                context.stroke(Path(ellipseIn: CGRect(x: center.x - 26 * 0.28, y: center.y - 26 * 0.28, width: 26 * 0.56, height: 26 * 0.56)), with: .color(theme.hue), lineWidth: 0.8)
                context.fill(Path(ellipseIn: CGRect(x: center.x - 26 * 0.12, y: center.y - 26 * 0.12, width: 26 * 0.24, height: 26 * 0.24)), with: .color(theme.hue))
            }
            context.stroke(Path(CGRect(x: f.x + f.bw + 2, y: f.y + f.bw + 2, width: f.w - 2 * f.bw - 4, height: f.h - 2 * f.bw - 4)), with: .color(theme.hue), lineWidth: 1.2)
            let hatchRect = CGRect(x: f.x + f.bw + 6, y: f.y + f.bw + 6, width: f.w - 2 * f.bw - 12, height: f.h - 2 * f.bw - 12)
            var hatch = context
            hatch.clip(to: Path(hatchRect))
            hatch.stroke(Guilloche.hatchPath(in: hatchRect), with: .color(theme.hue.opacity(0.55)), lineWidth: 0.45)
            let core = CGRect(x: f.x + f.bw + 16, y: f.y + f.bw + 16, width: f.w - 2 * f.bw - 32, height: f.h - 2 * f.bw - 32)
            context.fill(Path(core), with: .color(theme.paper))
            context.stroke(Path(core), with: .color(theme.hue), lineWidth: 0.8)
        }
    }

    /// 环绕英文:逐字符沿圆弧摆放(SwiftUI 无 textPath)。
    private func arcText(_ string: String, center: CGPoint, radius: Double, degrees: (from: Double, to: Double), flip: Bool) -> some View {
        let chars = Array(string)
        return ForEach(0..<chars.count, id: \.self) { index in
            let t = chars.count > 1 ? Double(index) / Double(chars.count - 1) : 0.5
            let angle = (degrees.from + (degrees.to - degrees.from) * t) * .pi / 180
            Text(String(chars[index]))
                .font(.system(size: 10.5, design: .serif).weight(.bold))
                .foregroundStyle(theme.hue)
                .rotationEffect(.radians(angle + (flip ? -.pi / 2 : .pi / 2)))
                .position(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        }
    }

    private func sideBlessing(x: Double, angle: Double) -> some View {
        Text(verbatim: "May your savings compound & your freedom arrive early.")
            .font(.system(size: 9.5, design: .serif)).kerning(1.4)
            .foregroundStyle(theme.hue)
            .fixedSize()
            .rotationEffect(.degrees(angle))
            .position(x: x, y: 330)
    }

    private func pixelCorner(x: Double, y: Double) -> some View {
        PixelDigits(text: String(age ?? 0), color: theme.hue)
            .frame(width: 26.4, height: 16.8)  // s=2.4:11×7 单位
            .position(x: x + 13.2, y: y + 8.4)
    }

    private var header: some View {
        let f = Self.frame
        return Group {
            serif("WEALTHCLOCK", size: 8.5, kerning: 3.4, bold: true).position(x: 180, y: f.y + f.bw + 34)
            serif("憑此約定", size: 9, kerning: 4).position(x: 180, y: f.y + f.bw + 50)
            Rectangle().fill(theme.hue).frame(width: 60, height: 0.8).position(x: 180, y: f.y + f.bw + 58)
        }
    }

    /// "自由"两个大字:Ma Shan Zheng(OFL,已打包)。
    private var bigCharacters: some View {
        let f = Self.frame
        return Group {
            Text("自").font(.custom("MaShanZheng-Regular", size: 150)).foregroundStyle(theme.hue)
                .position(x: 180, y: f.y + f.h / 2 - 60)
            Text("由").font(.custom("MaShanZheng-Regular", size: 150)).foregroundStyle(theme.hue)
                .position(x: 180, y: f.y + f.h / 2 + 76)
        }
    }

    private func verticalMotto(_ string: String, x: Double, y: Double) -> some View {
        VStack(spacing: 3) {
            ForEach(Array(string.enumerated()), id: \.offset) { _, char in
                Text(String(char)).font(.system(size: 9.5, design: .serif)).foregroundStyle(theme.hue)
            }
        }
        .position(x: x, y: y)
    }

    /// 两枚印:永远朱砂,不随主色走(设计铁律)。右竖印为密押,M4 占位。
    private var seals: some View {
        let f = Self.frame
        return Group {
            VStack(spacing: 2) {
                ForEach(Array("密押待定".enumerated()), id: \.offset) { _, char in
                    Text(String(char)).font(.system(size: 10, design: .serif)).foregroundStyle(Self.sealColor)
                }
            }
            .frame(width: 24, height: 64)
            .border(Self.sealColor, width: 1.8)
            .rotationEffect(.degrees(4))
            .position(x: f.x + f.w - f.bw - 14, y: f.y + f.bw + 70 + 32)
            Text("財")
                .font(.system(size: 20, design: .serif))
                .foregroundStyle(theme.paper)
                .frame(width: 30, height: 30)
                .background(Self.sealColor.opacity(0.92))
                .rotationEffect(.degrees(-6))
                .position(x: f.x + f.bw + 30, y: f.y + f.h - f.bw - 96)
        }
    }

    private var footer: some View {
        HStack {
            Text(verbatim: "No. \(String(format: "%07d", age ?? 0)) · 密押 待定")
            Spacer()
            Text(verbatim: "wealthclock.app")
        }
        .font(.system(size: 7.5, design: .monospaced)).kerning(1.5)
        .foregroundStyle(theme.hue)
        .frame(width: 272)
        .position(x: 180, y: 604)
    }

    private func serif(_ string: String, size: Double, kerning: Double, bold: Bool = false) -> some View {
        Text(verbatim: string)
            .font(.system(size: size, design: .serif).weight(bold ? .bold : .regular))
            .kerning(kerning)
            .foregroundStyle(theme.hue)
    }
}

/// 汇票页容器:卡片缩放适配屏幕 + ShareLink 导出(1080×1920 PNG)。
struct BillScreen: View {
    @State private var exportURL: URL?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Tokens.paper.ignoresSafeArea()
                BillView()
                    .scaleEffect(min(geo.size.width / 360, geo.size.height / 640) * 0.9)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let exportURL {
                    ShareLink(item: exportURL, preview: SharePreview("WealthClock 汇票")) {
                        Text("分享汇票")
                            .font(.system(size: 13, design: .serif)).kerning(2.4)
                            .foregroundStyle(Tokens.inkSoft)
                            .frame(maxWidth: .infinity, minHeight: 32)
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .task {
            exportURL = BillExporter.saveToDocuments()
        }
    }
}

#Preview { BillScreen() }
