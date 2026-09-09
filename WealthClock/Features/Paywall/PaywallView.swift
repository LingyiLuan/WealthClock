import StoreKit
import SwiftUI

/// 付费墙(BRIEF §6 Paywall):文案照原句;价格从商店读;一次性买断 + 恢复购买。
@MainActor
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store: StoreManager
    @State private var busy = false

    init() {
        _store = State(initialValue: StoreManager.shared)
    }

    var body: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("完整推演")
                    .font(.system(size: 12, design: .serif)).kerning(5)
                    .foregroundStyle(Tokens.inkSoft)
                    .padding(.top, 40)
                PixelCoin(face: .yang).frame(width: 44, height: 44)
                    .padding(.top, 18)
                Text("三情景结果与汇票永远免费。完整推演买断一次,永久可用。")
                    .font(.system(size: 15, design: .serif))
                    .lineSpacing(7)
                    .foregroundStyle(Tokens.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 22)
                VStack(alignment: .leading, spacing: 6) {
                    Text("· 曲线:三情景资产轨迹与自由线")
                    Text("· 归因:每个习惯各值几年,附文献依据")
                    Text("· 沙盘:拉动储蓄率与习惯,实时看年龄变化")
                }
                .font(.system(size: 12.5, design: .serif))
                .lineSpacing(4)
                .foregroundStyle(Tokens.inkSoft)
                .padding(.top, 14)
                if let product = store.product {
                    Text(verbatim: product.displayPrice)
                        .font(.system(size: 34, design: .serif))
                        .foregroundStyle(Tokens.giltDeep)
                        .padding(.top, 20)
                } else {
                    ProgressView().tint(Tokens.giltDeep).padding(.top, 24)
                }
                Spacer(minLength: 16)
                if let error = store.lastError {
                    Text(verbatim: error)
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(Tokens.cinnabar)
                        .padding(.bottom, 6)
                }
                Button {
                    guard !busy else { return }
                    busy = true
                    Task {
                        if await store.purchase() { dismiss() }
                        busy = false
                    }
                } label: {
                    Text(busy ? "处理中…" : "买断完整推演")
                        .font(.system(size: 15, design: .serif)).kerning(3)
                        .foregroundStyle(Tokens.paper)
                        .frame(maxWidth: .infinity, minHeight: Tokens.primaryButtonHeight)
                        .background(Tokens.ink)
                }
                .disabled(busy || store.product == nil)
                Button {
                    guard !busy else { return }
                    busy = true
                    Task {
                        await store.restore()
                        if store.isUnlocked { dismiss() }
                        busy = false
                    }
                } label: {
                    Text("恢复购买")
                        .font(.system(size: 13, design: .serif)).kerning(2.4)
                        .foregroundStyle(Tokens.inkSoft)
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .padding(.top, 6)
                Text("本应用提供的是基于公开文献的情景测算与传统文化趣味解读,不构成投资、财务或法律建议。")
                    .font(.system(size: 10.5, design: .serif))
                    .foregroundStyle(Tokens.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
            }
            .padding(.horizontal, Tokens.pageMargin)
        }
        .task { store.start() }
    }
}

#Preview { PaywallView() }
