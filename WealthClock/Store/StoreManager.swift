import Foundation
import StoreKit

/// StoreKit 2 封装(BRIEF:非消耗型买断 app.wealthclock.report.full;价格从商店读,代码不硬编码)。
/// 解锁状态唯一来源是 Transaction.currentEntitlements,不自存任何标记。
@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()
    static let productID = "app.wealthclock.report.full"

    private(set) var product: Product?
    private(set) var isUnlocked = false
    private(set) var lastError: String?
    private var updatesTask: Task<Void, Never>?

    private init() {}

    /// 启动监听 + 首次加载。可重复调用。
    func start() {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                for await update in Transaction.updates {
                    if case .verified(let transaction) = update {
                        await transaction.finish()
                    }
                    await self?.refreshEntitlement()
                }
            }
        }
        Task {
            await loadProduct()
            await refreshEntitlement()
        }
    }

    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// 解锁状态只信 StoreKit(BRIEF §6 Paywall;删除重装后由恢复购买/自动同步找回)。
    func refreshEntitlement() async {
        var unlocked = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        isUnlocked = unlocked
    }

    @discardableResult
    func purchase() async -> Bool {
        if product == nil { await loadProduct() }
        guard let product else {
            lastError = lastError ?? "商品加载失败"
            return false
        }
        do {
            let outcome = try await product.purchase()
            if case .success(let verification) = outcome, case .verified(let transaction) = verification {
                await transaction.finish()
                await refreshEntitlement()
                return isUnlocked
            }
            return false
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }
}
