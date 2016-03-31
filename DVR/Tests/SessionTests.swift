import XCTest
@testable import DVR

class SessionTests: XCTestCase {
    let session: Session = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = ["testSessionHeader": "testSessionHeaderValue"]
        let backingSession = NSURLSession(configuration: configuration)
        return Session(cassetteName: "example", backingSession: backingSession)
    }()

    let request = NSURLRequest(URL: NSURL(string: "http://example.com")!)

    func testInit() {
        XCTAssertEqual("example", session.cassetteName)
    }

    func testDataTask() {
        let request = NSURLRequest(URL: NSURL(string: "http://example.com")!)
        let dataTask = session.dataTaskWithRequest(request)
        
        XCTAssert(dataTask is SessionDataTask)
        
        if let dataTask = dataTask as? SessionDataTask, headers = dataTask.request.allHTTPHeaderFields {
            XCTAssert(headers["testSessionHeader"] == "testSessionHeaderValue")
        } else {
            XCTFail()
        }
    }

    func testDataTaskWithCompletion() {
        let request = NSURLRequest(URL: NSURL(string: "http://example.com")!)
        let dataTask = session.dataTaskWithRequest(request) { _, _, _ in return }
        
        XCTAssert(dataTask is SessionDataTask)
        
        if let dataTask = dataTask as? SessionDataTask, headers = dataTask.request.allHTTPHeaderFields {
            XCTAssert(headers["testSessionHeader"] == "testSessionHeaderValue")
        } else {
            XCTFail()
        }
    }

    func testPlayback() {
        session.recordingEnabled = false
        let expectation = expectationWithDescription("Network")

        session.dataTaskWithRequest(request) { data, response, error in
            XCTAssertEqual("hello", String(data: data!, encoding: NSUTF8StringEncoding))

            let HTTPResponse = response as! NSHTTPURLResponse
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }.resume()

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testTextPlayback() {
        let session = Session(cassetteName: "text")
        session.recordingEnabled = false

        let request = NSMutableURLRequest(URL: NSURL(string: "http://example.com")!)
        request.HTTPMethod = "POST"
        request.HTTPBody = "Some text.".dataUsingEncoding(NSUTF8StringEncoding)
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        let expectation = expectationWithDescription("Network")

        session.dataTaskWithRequest(request) { data, response, error in
            XCTAssertEqual("hello", String(data: data!, encoding: NSUTF8StringEncoding))

            let HTTPResponse = response as! NSHTTPURLResponse
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }.resume()

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testDownload() {
        let expectation = expectationWithDescription("Network")

        let session = Session(cassetteName: "json-example")
        session.recordingEnabled = false

        let request = NSURLRequest(URL: NSURL(string: "https://www.howsmyssl.com/a/check")!)

        session.downloadTaskWithRequest(request) { location, response, error in
            let data = NSData(contentsOfURL: location!)!
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject]
                XCTAssertEqual("TLS 1.2", JSON?["tls_version"] as? String)
            } catch {
                XCTFail("Failed to read JSON.")
            }

            let HTTPResponse = response as! NSHTTPURLResponse
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }.resume()

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testMultiple() {
        let expectation = expectationWithDescription("Network")
        let session = Session(cassetteName: "multiple")
        session.beginRecording()

        let apple = expectationWithDescription("Apple")
        let google = expectationWithDescription("Google")

        session.dataTaskWithRequest(NSURLRequest(URL: NSURL(string: "http://apple.com")!)) { _, response, _ in
            XCTAssertEqual(200, (response as? NSHTTPURLResponse)?.statusCode)

            dispatch_async(dispatch_get_main_queue()) {
                session.dataTaskWithRequest(NSURLRequest(URL: NSURL(string: "http://google.com")!)) { _, response, _ in
                    XCTAssertEqual(200, (response as? NSHTTPURLResponse)?.statusCode)
                    google.fulfill()
                }.resume()

                session.endRecording() {
                    expectation.fulfill()
                }
            }

            apple.fulfill()
        }.resume()

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testTaskDelegate() {
        class Delegate: NSObject, NSURLSessionTaskDelegate {
            let expectation: XCTestExpectation
            var response: NSURLResponse?

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            @objc private func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
                response = task.response
                expectation.fulfill()
            }
        }

        let expectation = expectationWithDescription("didCompleteWithError")
        let delegate = Delegate(expectation: expectation)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let backingSession = NSURLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        let session = Session(cassetteName: "example", backingSession: backingSession)
        session.recordingEnabled = false

        let task = session.dataTaskWithRequest(request)
        task.resume()

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testDataDelegate() {
        class Delegate: NSObject, NSURLSessionDataDelegate {
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            @objc func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
                expectation.fulfill()
            }
        }

        let expectation = expectationWithDescription("didCompleteWithError")
        let delegate = Delegate(expectation: expectation)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let backingSession = NSURLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        let session = Session(cassetteName: "example", backingSession: backingSession)
        session.recordingEnabled = false

        let task = session.dataTaskWithRequest(request)
        task.resume()

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
