import XCTest
@testable import DVR

class SessionTests: XCTestCase {
    let session = Session(cassetteName: "example")
    let request = NSURLRequest(URL: NSURL(string: "http://example.com")!)

    func testInit() {
        XCTAssertEqual("example", session.cassetteName)
    }

    func testDataTask() {
        let request = NSURLRequest(URL: NSURL(string: "http://example.com")!)
        XCTAssert(session.dataTaskWithRequest(request) is SessionDataTask)
        XCTAssert(session.dataTaskWithRequest(request) { _, _, _ in return } is SessionDataTask)
    }

    func testPlayback() {
        session.recordingEnabled = false
        let expectation = expectationWithDescription("Network")

        let task = session.dataTaskWithRequest(request) { data, response, error in
            XCTAssertEqual("hello", String(NSString(data: data!, encoding: NSUTF8StringEncoding)!))
            expectation.fulfill()
        }
        task?.resume()
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
