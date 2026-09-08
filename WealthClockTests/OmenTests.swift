import XCTest
@testable import WealthClock
import FreedomEngine

final class OmenTests: XCTestCase {
    /// 同日同 Profile 抽取稳定;不同日可不同(不断言不同,只断言函数确定性)。
    func testOmenStableForSameProfileAndDay() {
        XCTAssertEqual(OmenPicker.entries.count, 30)
        let day = Date(timeIntervalSince1970: 1_790_000_000)
        let first = OmenPicker.pick(for: Profile.sample, on: day)
        let second = OmenPicker.pick(for: Profile.sample, on: day)
        XCTAssertEqual(first, second)
        let sameDayLater = OmenPicker.pick(for: Profile.sample, on: day.addingTimeInterval(3600))
        XCTAssertEqual(first, sameDayLater, "同一天内复看不变")
        let otherDay = OmenPicker.pick(for: Profile.sample, on: day.addingTimeInterval(86_400 * 3))
        XCTAssertTrue(OmenPicker.entries.contains(otherDay))
        XCTAssertEqual(OmenPicker.stableHash(Profile.sample), OmenPicker.stableHash(Profile.sample))
    }

    func testYearGanzhi() {
        // 2026 = 丙午(甲子起 1984)。
        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 1))
        XCTAssertEqual(OmenPicker.yearGanzhi(for: date ?? .now), "丙午")
    }
}
