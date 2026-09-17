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
                    if let transaction = Self.accepted(update) {
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

    /// 验签放行规则:正式/沙盒必须 .verified;仅 Xcode 本地测试环境接受 .unverified——
    /// 新 Xcode 模拟器用 scheme 挂 .storekit 时存在已知验签证书问题(SKTestSession 自装测试证书,
    /// 故单测绿而真实路径 .unverified),environment == .xcode 不可能出现在生产。
    static func accepted(_ result: VerificationResult<Transaction>) -> Transaction? {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified(let transaction, let error):
            // 仅限调试:scheme 挂 .storekit 时,新 Xcode 模拟器的本地交易验签可能返回 .unverified
            // (SKTestSession 自装测试证书故单测不受影响)。放行条件双保险:DEBUG 构建 + env==.xcode。
            // Release 构建下 .unverified 无条件拒绝(L0 审阅意见,2026-09-17)。
            #if DEBUG
            if transaction.environment == .xcode {
                print("STOREKIT-DIAG unverified accepted (env=xcode, DEBUG build): \(error.localizedDescription)")
                return transaction
            }
            #else
            _ = transaction
            _ = error
            #endif
            return nil
        }
    }

    /// 解锁状态只信 StoreKit(BRIEF §6 Paywall;删除重装后由恢复购买/自动同步找回)。
    func refreshEntitlement() async {
        var unlocked = false
        for await entitlement in Transaction.currentEntitlements {
            if let transaction = Self.accepted(entitlement), owns(transaction) {
                unlocked = true
            }
        }
        isUnlocked = unlocked
    }

    private func owns(_ transaction: Transaction) -> Bool {
        transaction.productID == Self.productID && transaction.revocationDate == nil
    }

    @discardableResult
    func purchase() async -> Bool {
        if product == nil { await loadProduct() }
        guard let product else {
            lastError = lastError ?? String(localized: "商品加载失败")
            return false
        }
        do {
            let outcome = try await product.purchase()
            if case .success(let verification) = outcome {
                if let transaction = Self.accepted(verification) {
                    await transaction.finish()
                } else {
                    lastError = String(localized: "交易验签失败")
                    print("STOREKIT-DIAG purchase success but verification rejected (non-xcode env)")
                }
                await refreshEntitlement()
                return isUnlocked
            }
            print("STOREKIT-DIAG purchase outcome not .success: \(outcome)")
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
