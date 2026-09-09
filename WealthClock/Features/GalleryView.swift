// l10n-ignore-file(汇票/密押/画廊为设计与玄学层,文案不随语言变)
#if DEBUG
import SwiftUI

/// Debug 组件画廊(M2 验收用):启动参数 -gallery 直达。与设计稿并排目视比对。
struct GalleryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                section("点阵数字 5×7") {
                    PixelDigits(text: "0123456789", color: Tokens.ink)
                        .frame(height: 28)
                    PixelDigits(text: "47")
                        .frame(height: 96)
                }
                section("像素铜钱 11×11") {
                    HStack(spacing: 24) {
                        PixelCoin(face: .yang).frame(width: 66, height: 66)
                        PixelCoin(face: .yin).frame(width: 66, height: 66)
                        PixelCoin(face: .yang).frame(width: 33, height: 33)
                    }
                }
                section("花边:角饰 / 边带 / 底纹") {
                    HStack(spacing: 16) {
                        GuillocheCorner().frame(width: 110, height: 110)
                        GuillocheCorner(color: Tokens.cinnabar).frame(width: 72, height: 72)
                    }
                    GuillocheEdgeBand().frame(height: 26)
                    GuillocheHatch().frame(height: 60)
                        .background(Tokens.paper2)
                }
                section("六爻进度") {
                    HStack(spacing: 24) {
                        ForEach([0, 3, 6], id: \.self) { lit in
                            Hexagram(lit: lit).frame(width: 56, height: 64)
                        }
                    }
                }
                section("色板") {
                    let colors: [(String, Color)] = [
                        ("paper", Tokens.paper), ("paper2", Tokens.paper2), ("ink", Tokens.ink),
                        ("inkSoft", Tokens.inkSoft), ("cinnabar", Tokens.cinnabar), ("gilt", Tokens.gilt),
                        ("giltDeep", Tokens.giltDeep), ("verdigris", Tokens.verdigris)
                    ]
                    ForEach(colors, id: \.0) { name, color in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 44, height: 22)
                            Text(verbatim: name).font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Tokens.inkSoft)
                        }
                    }
                }
            }
            .padding(Tokens.pageMargin)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Tokens.paper.ignoresSafeArea())
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: title)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Tokens.ink)
            content()
        }
    }
}

#Preview { GalleryView() }
#endif
