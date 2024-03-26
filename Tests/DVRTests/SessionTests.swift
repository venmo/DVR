import XCTest
import Foundation
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

        XCTAssertEqual(dataTask.currentRequest?.url?.absoluteString, request.url?.absoluteString)
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
    
    func testDataTaskWithUrl() {
        let url = URL(string: "http://example.com")!
        let dataTask = session.dataTask(with: url)
        
        XCTAssert(dataTask is SessionDataTask)
        
        if let dataTask = dataTask as? SessionDataTask, let headers = dataTask.request.allHTTPHeaderFields {
            XCTAssert(headers["testSessionHeader"] == "testSessionHeaderValue")
        } else {
            XCTFail()
        }
    }

    func testDataTaskWithUrlAndCompletion() {
        let url = URL(string: "http://example.com")!
        let dataTask = session.dataTask(with: url, completionHandler: { _, _, _ in return })
        
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

            let httpResponse = response as! Foundation.HTTPURLResponse
            XCTAssertEqual(200, httpResponse.statusCode)

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

        session.dataTask(with: request, completionHandler: { data, response, error in
            XCTAssertEqual("hello", String(data: data!, encoding: String.Encoding.utf8))

            let httpResponse = response as! Foundation.HTTPURLResponse
            XCTAssertEqual(200, httpResponse.statusCode)

            expectation.fulfill()
        }) .resume()

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testTextPlaybackWithAllParamsWithoutIgnoredParameter() {
        let session = Session(cassetteName: "response-headers")

        let request = URLRequest(url: URL(string: "https://httpbin.org/response-headers?apiKey=val&format=json")!)
        let expectation = self.expectation(description: "Network")

        session.dataTask(with: request, completionHandler: { data, response, error in
            let httpResponse = response as? Foundation.HTTPURLResponse
            XCTAssertEqual(200, httpResponse?.statusCode)
            
            guard let data else { XCTFail("data is nil"); return }
            
            guard let JSONDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                XCTFail("JSONDict is nil"); return
            }
            
            XCTAssertEqual(JSONDict["Content-Length"] as? String, "110")
            XCTAssertEqual(JSONDict["Content-Type"] as? String, "application/json")
            XCTAssertEqual(JSONDict["apiKey"] as? String, "val")
            XCTAssertEqual(JSONDict["format"] as? String, "json")
            expectation.fulfill()
        }).resume()

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testTextPlaybackWithAllParamsWithIgnoredParameter() {
        let session = Session(cassetteName: "response-headers-without-apikey", parametersToIgnore: ["apiKey"])

        let request = URLRequest(url: URL(string: "https://httpbin.org/response-headers?apiKey=val&format=json")!)
        let expectation = self.expectation(description: "Network")

        session.dataTask(with: request, completionHandler: { data, response, error in
            let httpResponse = response as? Foundation.HTTPURLResponse
            XCTAssertEqual(200, httpResponse?.statusCode)
            
            guard let data else { XCTFail("data is nil"); return }
            
            guard let JSONDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                XCTFail("JSONDict is nil"); return
            }
            
            XCTAssertEqual(JSONDict["Content-Length"] as? String, "110")
            XCTAssertEqual(JSONDict["Content-Type"] as? String, "application/json")
            XCTAssertEqual(JSONDict["apiKey"] as? String, nil)
            XCTAssertEqual(JSONDict["format"] as? String, "json")
            expectation.fulfill()
        }).resume()

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
                let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                XCTAssertEqual("TLS 1.2", JSON?["tls_version"] as? String)
            } catch {
                XCTFail("Failed to read JSON.")
            }

            let httpResponse = response as! Foundation.HTTPURLResponse
            XCTAssertEqual(200, httpResponse.statusCode)

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
            XCTAssertEqual(200, (response as? Foundation.HTTPURLResponse)?.statusCode)

            DispatchQueue.main.async {
                session.dataTask(with: URLRequest(url: URL(string: "http://google.com")!), completionHandler: { _, response, _ in
                    XCTAssertEqual(200, (response as? Foundation.HTTPURLResponse)?.statusCode)
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

    func testTaskDelegate() {
        class Delegate: NSObject, URLSessionTaskDelegate {
            let expectation: XCTestExpectation
            var response: Foundation.URLResponse?

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            @objc fileprivate func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
                response = task.response
                expectation.fulfill()
            }
        }

        let expectation = self.expectation(description: "didCompleteWithError")
        let delegate = Delegate(expectation: expectation)
        let config = URLSessionConfiguration.default
        let backingSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        let session = Session(cassetteName: "example", backingSession: backingSession)
        session.recordingEnabled = false

        let task = session.dataTask(with: request)
        task.resume()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDataDelegate() {
        class Delegate: NSObject, URLSessionDataDelegate {
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            @objc func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
                expectation.fulfill()
            }
        }

        let expectation = self.expectation(description: "didCompleteWithError")
        let delegate = Delegate(expectation: expectation)
        let config = URLSessionConfiguration.default
        let backingSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        let session = Session(cassetteName: "example", backingSession: backingSession)
        session.recordingEnabled = false

        let task = session.dataTask(with: request)
        task.resume()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRecordingStatusCodeForFailedRequest() {
        let expectation = self.expectation(description: "didCompleteWithError")

        let request = URLRequest(url: URL(string: "http://cdn.contentful.com/spaces/cfexampleapi/entries")!)

        let config = URLSessionConfiguration.default
        let backingSession = URLSession(configuration: config)
        let session = Session(cassetteName: "failed-request-example", backingSession: backingSession)

        let task = session.dataTask(with: request) { (_, urlResponse, _) in
            XCTAssertNotEqual(200, (urlResponse as? Foundation.HTTPURLResponse)?.statusCode)
            XCTAssertEqual(401, (urlResponse as? Foundation.HTTPURLResponse)?.statusCode)
            expectation.fulfill()
        }
        task.resume()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSameRequestWithDifferentHeaders() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["testSessionHeader": "testSessionHeaderValue"]
        let backingSession = URLSession(configuration: configuration)
        let session = Session(cassetteName: "different-headers", backingSession: backingSession, headersToCheck: ["Foo"])
        session.recordingEnabled = false

        var request = URLRequest(url: URL(string: "http://example.com")!)
        request.setValue("Bar1", forHTTPHeaderField: "Foo")

        let firstExpectation = self.expectation(description: "request 1 completed")
        session.dataTask(with: request, completionHandler: { data, response, error in
            XCTAssertEqual("hello", String(data: data!, encoding: String.Encoding.utf8))

            let httpResponse = response as! Foundation.HTTPURLResponse
            XCTAssertEqual(200, httpResponse.statusCode)

            firstExpectation.fulfill()
        }) .resume()

        let secondExpectation = self.expectation(description: "request 2 completed")
        request.setValue("Bar2", forHTTPHeaderField: "Foo")
        session.dataTask(with: request, completionHandler: { data, response, error in
            XCTAssertEqual("hello again", String(data: data!, encoding: String.Encoding.utf8))

            let httpResponse = response as! Foundation.HTTPURLResponse
            XCTAssertEqual(200, httpResponse.statusCode)

            secondExpectation.fulfill()
        }) .resume()

        wait(for: [firstExpectation, secondExpectation], timeout: 3.0)
    }
    
    
    func testTextPlaybackWithParams() {
        let session = Session(cassetteName: "text-with-param", parametersToIgnore: ["key"])
        session.recordingEnabled = false

        var request = URLRequest(url: URL(string: "http://example.com?status=Available&key=Wmw0860")!)
        request.httpMethod = "POST"
        request.httpBody = "Some text.".data(using: String.Encoding.utf8)
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        let expectation = self.expectation(description: "Network")

        session.dataTask(with: request, completionHandler: { data, response, error in
            XCTAssertEqual("hello", String(data: data!, encoding: String.Encoding.utf8))

            let httpResponse = response as! Foundation.HTTPURLResponse
            XCTAssertEqual(200, httpResponse.statusCode)

            expectation.fulfill()
        }).resume()

        waitForExpectations(timeout: 1, handler: nil)
    }

}
