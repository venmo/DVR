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

			let HTTPResponse = response as! NSHTTPURLResponse
			XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }
        task.resume()
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testDownload() {
        let expectation = expectationWithDescription("Network")

        let session = Session(cassetteName: "json-example")
        session.recordingEnabled = false
        let request = NSURLRequest(URL: NSURL(string: "https://www.howsmyssl.com/a/check")!)
        
        let task = session.downloadTaskWithRequest(request) { location, response, error in
            let data = NSData(contentsOfURL: location!)!
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! [String: AnyObject]
                XCTAssertEqual("TLS 1.2", JSON["tls_version"]! as! String)
            } catch {
                XCTFail("Failed to read JSON.")
            }

            let HTTPResponse = response as! NSHTTPURLResponse
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }
        task.resume()
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
