import SwiftUI

/// 六爻进度条:自下而上落爻,阳爻实线、阴爻断线(BRIEF §4:前 6 题一爻一根)。
struct Hexagram: View {
    /// 已落爻数 0...6。
    var lit: Int
    /// 自下而上的爻性,true=阳(实)、false=阴(断)。默认既济卦(水火既济,交替)。
    var pattern: [Bool] = [true, false, true, false, true, false]
    var litColor: Color = Tokens.ink
    var dimColor: Color = Tokens.inkSoft.opacity(0.25)

    var body: some View {
        Canvas { context, size in
            let rows = 6
            let barHeight = size.height / (CGFloat(rows) * 2 - 1)
            let gap = size.width * 0.18
            for index in 0..<rows {
                let yang = index < pattern.count ? pattern[index] : true
                let color = index < lit ? litColor : dimColor
                let y = size.height - CGFloat(index * 2 + 1) * barHeight
                if yang {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: barHeight)
                    context.fill(Path(rect), with: .color(color))
                } else {
                    let segment = (size.width - gap) / 2
                    context.fill(Path(CGRect(x: 0, y: y, width: segment, height: barHeight)), with: .color(color))
                    context.fill(
                        Path(CGRect(x: size.width - segment, y: y, width: segment, height: barHeight)),
                        with: .color(color)
                    )
                }
            }
        }
        .accessibilityLabel(Text("进度 \(lit)/6"))
    }
}
