import XCTest
@testable import SwiftSileroVAD

final class SwiftSileroVADTests: XCTestCase {
    func testInit() throws {
        XCTAssertNoThrow(try SileroVAD())
    }
}
