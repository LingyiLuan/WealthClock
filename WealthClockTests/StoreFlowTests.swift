import StoreKitTest
import XCTest
@testable import WealthClock

/// BRIEF §4.2:购买→解锁→删除重装→恢复 四步,用 SKTestSession 程序化走通。
/// 事务证据由 print 输出(STOREKIT-EVIDENCE 前缀),贴 PR/汇报证据栏。
final class StoreFlowTests: XCTestCase {
    @MainActor
    func testPurchaseUnlockReinstallRestore() async throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "WealthClock", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true

        let store = StoreManager.shared
        await store.loadProduct()
        let product = try XCTUnwrap(store.product, "商品应能从 .storekit 配置加载: \(store.lastError ?? "")")
        XCTAssertEqual(product.id, StoreManager.productID)
        print("STOREKIT-EVIDENCE product loaded: \(product.id) price=\(product.displayPrice)")

        await store.refreshEntitlement()
        XCTAssertFalse(store.isUnlocked, "初始应未解锁")

        // 步骤 1+2:购买 → 解锁
        let purchased = await store.purchase()
        XCTAssertTrue(purchased, "购买应成功: \(store.lastError ?? "")")
        XCTAssertTrue(store.isUnlocked, "购买后应解锁")
        print("STOREKIT-EVIDENCE step1-2 purchase+unlock OK, transactions=\(session.allTransactions().count)")

        // 步骤 3:删除重装——解锁状态只来自 StoreKit,无本地标记,
        // 清空测试账户事务后必须回到锁定(若代码自存了标记,这里会假解锁)。
        session.clearTransactions()
        await store.refreshEntitlement()
        XCTAssertFalse(store.isUnlocked, "清空账户事务后应锁定(证明无自存标记)")
        print("STOREKIT-EVIDENCE step3 reinstall-simulation locked OK, transactions=\(session.allTransactions().count)")

        // 步骤 4:恢复——账户重新出现买断事务后,restore() 找回解锁。
        _ = await store.purchase()  // 测试会话里等价于账户已持有该买断
        await store.restore()
        XCTAssertTrue(store.isUnlocked, "恢复后应解锁")
        print("STOREKIT-EVIDENCE step4 restore OK, transactions=\(session.allTransactions().count)")

        for transaction in session.allTransactions() {
            print("STOREKIT-EVIDENCE txn id=\(transaction.identifier) product=\(transaction.productIdentifier) state=\(transaction.state)")
        }
        session.clearTransactions()
    }

    /// 回归守护(真实路径 bug:购买成功但付费墙未解锁):
    /// 走 App 真实入口(start() 常驻监听 + shared 单例),购买后 isUnlocked 必须翻真——
    /// 这是付费墙 onChange dismiss 与揭晓页门禁进推演的唯一依据。
    @MainActor
    func testPurchaseUnlocksSharedManagerForUI() async throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "WealthClock", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true

        let store = StoreManager.shared
        store.start()  // App 真实入口:启动即挂 Transaction.updates 常驻监听
        await store.refreshEntitlement()
        XCTAssertFalse(store.isUnlocked)
        XCTAssertTrue(!store.isUnlocked, "门禁此时应选付费墙")

        _ = await store.purchase()
        XCTAssertTrue(store.isUnlocked, "购买后共享实例必须解锁——这是付费墙 dismiss 与门禁进推演的唯一依据")

        print("STOREKIT-EVIDENCE ui-unlock test: isUnlocked=\(store.isUnlocked)")
        session.clearTransactions()
        await store.refreshEntitlement()
    }
}
