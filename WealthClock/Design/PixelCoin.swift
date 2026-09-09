import SwiftUI

/// 11×11 像素铜钱,Canvas 画矩形(设计系统铁律 1)。
/// 位图来自 tokens.md;阳面外圈 giltDeep、内部 gilt,阴面全 ink,方孔留空。
struct PixelCoin: View {
    enum Face {
        case yang, yin
    }

    var face: Face = .yang

    private static let bitmap = [
        "   #####   ",
        "  #######  ",
        " ######### ",
        "###########",
        "####...####",
        "####...####",
        "####...####",
        "###########",
        " ######### ",
        "  #######  ",
        "   #####   "
    ]

    private static func isRim(_ row: Int, _ col: Int) -> Bool {
        let grid = bitmap
        let neighbors = [(row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1)]
        return neighbors.contains { r, c in
            guard r >= 0, r < 11, c >= 0, c < 11 else { return true }
            return Array(grid[r])[c] == " "
        }
    }

    var body: some View {
        Canvas { context, size in
            let unit = min(size.width, size.height) / 11
            let origin = CGPoint(x: (size.width - unit * 11) / 2, y: (size.height - unit * 11) / 2)
            for (row, line) in Self.bitmap.enumerated() {
                for (col, ch) in line.enumerated() where ch == "#" {
                    let color: Color = switch face {
                    case .yin: Tokens.ink
                    case .yang: Self.isRim(row, col) ? Tokens.giltDeep : Tokens.gilt
                    }
                    let rect = CGRect(
                        x: origin.x + CGFloat(col) * unit,
                        y: origin.y + CGFloat(row) * unit,
                        width: unit,
                        height: unit
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .accessibilityLabel(Text(face == .yang ? LocalizedStringKey("铜钱阳面") : LocalizedStringKey("铜钱阴面")))
    }
}
