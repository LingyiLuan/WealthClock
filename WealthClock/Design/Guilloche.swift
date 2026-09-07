import SwiftUI

/// 雕版花边,方程与参数写死自 tokens.md(sharecard_v3.html 同源),保证每次渲染一致。
enum Guilloche {
    /// 角饰:r(θ) = R·(0.62 + 0.16·sin(6θ+φ) + 0.09·sin(11θ−2φ) + 0.05·sin(17θ+3φ)),
    /// 10 层,φ = seed + k·0.31,θ 步长 3°。
    static func cornerPath(radius: CGFloat, center: CGPoint, seed: Double = 0) -> Path {
        var path = Path()
        for layer in 0..<10 {
            let phi = seed + Double(layer) * 0.31
            var first = true
            for step in 0...120 {
                let theta = Double(step) * 3 * .pi / 180
                let r = Double(radius) * (0.62
                    + 0.16 * sin(6 * theta + phi)
                    + 0.09 * sin(11 * theta - 2 * phi)
                    + 0.05 * sin(17 * theta + 3 * phi))
                let point = CGPoint(x: center.x + r * cos(theta), y: center.y + r * sin(theta))
                if first {
                    path.move(to: point)
                    first = false
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
        return path
    }

    /// 边带:7 条交织线,offset = (w/2)·sin(u/7.5+φ)·cos(u/41+k),φ = k·π/3.5。
    static func edgeBandPath(length: CGFloat, bandWidth: CGFloat) -> Path {
        var path = Path()
        for k in 0..<7 {
            let phi = Double(k) * .pi / 3.5
            var first = true
            var u = 0.0
            while u <= Double(length) {
                let offset = Double(bandWidth) / 2 * sin(u / 7.5 + phi) * cos(u / 41 + Double(k))
                let point = CGPoint(x: u, y: Double(bandWidth) / 2 + offset)
                if first {
                    path.move(to: point)
                    first = false
                } else {
                    path.addLine(to: point)
                }
                u += 2
            }
        }
        return path
    }

    /// 内框底纹:45° 平行细线,间距 3。
    static func hatchPath(in rect: CGRect) -> Path {
        var path = Path()
        var offset = -rect.height
        while offset < rect.width {
            path.move(to: CGPoint(x: rect.minX + offset, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + offset + rect.height, y: rect.minY))
            offset += 3
        }
        return path
    }
}

/// 角饰 View。线宽 0.55。
struct GuillocheCorner: View {
    var color: Color = Tokens.giltDeep

    var body: some View {
        Canvas { context, size in
            let radius = min(size.width, size.height) / 2 / 0.92  // r 峰值 0.92R,撑满画布
            let path = Guilloche.cornerPath(radius: radius, center: CGPoint(x: size.width / 2, y: size.height / 2))
            context.stroke(path, with: .color(color), lineWidth: 0.55)
        }
    }
}

/// 边带 View。线宽 0.5。
struct GuillocheEdgeBand: View {
    var color: Color = Tokens.giltDeep

    var body: some View {
        Canvas { context, size in
            let path = Guilloche.edgeBandPath(length: size.width, bandWidth: size.height)
            context.stroke(path, with: .color(color), lineWidth: 0.5)
        }
    }
}

/// 底纹 View。线宽 0.45,透明度 0.55。
struct GuillocheHatch: View {
    var color: Color = Tokens.giltDeep

    var body: some View {
        Canvas { context, size in
            let path = Guilloche.hatchPath(in: CGRect(origin: .zero, size: size))
            context.stroke(path, with: .color(color.opacity(0.55)), lineWidth: 0.45)
        }
        .clipped()
    }
}
