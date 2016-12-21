import XCTest
@testable import DVR

class SessionTests: XCTestCase {
    let session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["testSessionHeader": "testSessionHeaderValue"]
        let backingSession = URLSession(configuration: configuration)
        return Session(cassetteName: "example", backingSession: backingSession)
    }()

    let request = URLRequest(url: URL(string: "http://example.com")!)

    func testInit() {
        XCTAssertEqual("example", session.cassetteName)
    }

    func testDataTask() {
        let request = URLRequest(url: URL(string: "http://example.com")!)
        let dataTask = session.dataTask(with: request)
        
        XCTAssert(dataTask is SessionDataTask)
        
        if let dataTask = dataTask as? SessionDataTask, let headers = dataTask.request.allHTTPHeaderFields {
            XCTAssert(headers["testSessionHeader"] == "testSessionHeaderValue")
        } else {
            XCTFail()
        }
    }

    func testDataTaskWithCompletion() {
        let request = URLRequest(url: URL(string: "http://example.com")!)
        let dataTask = session.dataTask(with: request, completionHandler: { _, _, _ in return }) 
        
        XCTAssert(dataTask is SessionDataTask)
        
        if let dataTask = dataTask as? SessionDataTask, let headers = dataTask.request.allHTTPHeaderFields {
            XCTAssert(headers["testSessionHeader"] == "testSessionHeaderValue")
        } else {
            XCTFail()
        }
    }

    func testPlayback() {
        session.recordingEnabled = false
        let expectation = self.expectation(description: "Network")

        session.dataTask(with: request, completionHandler: { data, response, error in
            XCTAssertEqual("hello", String(data: data!, encoding: String.Encoding.utf8))

            let HTTPResponse = response as! HTTPURLResponse
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }) .resume()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testTextPlayback() {
        let session = Session(cassetteName: "text")
        session.recordingEnabled = false

        var request = URLRequest(url: URL(string: "http://example.com")!)
        request.httpMethod = "POST"
        request.httpBody = "Some text.".data(using: String.Encoding.utf8)
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        let expectation = self.expectation(description: "Network")

        session.dataTask(with: request) { data, response, error in
            XCTAssertEqual("hello", String(data: data!, encoding: String.Encoding.utf8))

            let HTTPResponse = response as! HTTPURLResponse
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }.resume()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDownload() {
        let expectation = self.expectation(description: "Network")

        let session = Session(cassetteName: "json-example")
        session.recordingEnabled = false

        let request = URLRequest(url: URL(string: "https://www.howsmyssl.com/a/check")!)

        session.downloadTask(with: request, completionHandler: { location, response, error in
            let data = try! Data(contentsOf: location!)
            do {
                let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
                XCTAssertEqual("TLS 1.2", JSON?["tls_version"] as? String)
            } catch {
                XCTFail("Failed to read JSON.")
            }

            let HTTPResponse = response as! HTTPURLResponse
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }) .resume()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMultiple() {
        let expectation = self.expectation(description: "Network")
        let session = Session(cassetteName: "multiple")
        session.beginRecording()

        let apple = self.expectation(description: "Apple")
        let google = self.expectation(description: "Google")

        session.dataTask(with: URLRequest(url: URL(string: "http://apple.com")!), completionHandler: { _, response, _ in
            XCTAssertEqual(200, (response as? HTTPURLResponse)?.statusCode)

            DispatchQueue.main.async {
                session.dataTask(with: URLRequest(url: URL(string: "http://google.com")!), completionHandler: { _, response, _ in
                    XCTAssertEqual(200, (response as? HTTPURLResponse)?.statusCode)
                    google.fulfill()
                }) .resume()

                session.endRecording() {
                    expectation.fulfill()
                }
            }

            apple.fulfill()
        }) .resume()

        waitForExpectations(timeout: 1, handler: nil)
    }
}
