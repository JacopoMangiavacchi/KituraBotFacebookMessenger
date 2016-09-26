import XCTest
@testable import KituraBotFacebookMessenger

class KituraBotFacebookMessengerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(KituraBotFacebookMessenger().text, "Hello, World!")
    }


    static var allTests : [(String, (KituraBotFacebookMessengerTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
