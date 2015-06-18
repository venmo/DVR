import XCTest
@testable import DVR

class SessionTests: XCTestCase {
    let session = Session(cassettesDirectory: "/Users/soffes/Desktop/cassettes/", cassetteName: "test")

    func testInit() {
        XCTAssertEqual("/Users/soffes/Desktop/cassettes/", session.cassettesDirectory)
        XCTAssertEqual("test", session.cassetteName)
    }

    func testDataTask() {
        let request = NSURLRequest(URL: NSURL(string: "http://example.com")!)
        XCTAssert(session.dataTaskWithRequest(request) is SessionDataTask)
        XCTAssert(session.dataTaskWithRequest(request) { _, _, _ in return } is SessionDataTask)
    }
}
