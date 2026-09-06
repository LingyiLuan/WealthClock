import XCTest
@testable import WealthClock
import FreedomEngine

final class SmokeTests: XCTestCase {
    func testSampleProfileProducesThreeScenarios() {
        let result = FreedomEngine.run(Profile.sample)
        XCTAssertEqual(result.scenarios.count, 3)
    }
}
