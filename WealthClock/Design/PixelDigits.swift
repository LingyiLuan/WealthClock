import SwiftUI

/// 5×7 点阵数字,Canvas 画矩形,不用字体(设计系统铁律 1)。
/// 位图与格距来自 tokens.md:格子 0.9 单位,间距 1 单位。
struct PixelDigits: View {
    let text: String
    var color: Color = Tokens.gilt

    private static let bitmaps: [Character: [String]] = [
        "0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
        "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
        "2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
        "3": ["11111", "00010", "00100", "00010", "00001", "10001", "01110"],
        "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
        "5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
        "6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
        "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
        "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
        "9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"]
    ]

    var body: some View {
        Canvas { context, size in
            let digits = text.compactMap { Self.bitmaps[$0] }
            guard !digits.isEmpty else { return }
            let unitsWide = CGFloat(digits.count * 6 - 1)  // 每字 5 单位 + 字间 1 单位
            let unit = min(size.width / unitsWide, size.height / 7)
            let cell = unit * 0.9
            let origin = CGPoint(
                x: (size.width - unitsWide * unit) / 2,
                y: (size.height - 7 * unit) / 2
            )
            for (index, bitmap) in digits.enumerated() {
                let left = origin.x + CGFloat(index * 6) * unit
                for (row, bits) in bitmap.enumerated() {
                    for (col, bit) in bits.enumerated() where bit == "1" {
                        let rect = CGRect(
                            x: left + CGFloat(col) * unit,
                            y: origin.y + CGFloat(row) * unit,
                            width: cell,
                            height: cell
                        )
                        context.fill(Path(rect), with: .color(color))
                    }
                }
            }
        }
        .accessibilityLabel(Text(verbatim: text))
    }
}
