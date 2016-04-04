import XCTest
@testable import DVR

class SessionUploadTests: XCTestCase {

    lazy var request: NSURLRequest = {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://httpbin.org/post")!)
        request.HTTPMethod = "POST"

        let contentType = "multipart/form-data; boundary=\(self.multipartBoundary)"
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        return request
    }()
    let multipartBoundary = "---------------------------3klfenalksjflkjoi9auf89eshajsnl3kjnwal".UTF8Data()
    lazy var testFile: NSURL = {
        return NSBundle(forClass: self.dynamicType).URLForResource("testfile", withExtension: "txt")!
    }()

    func testUploadFile() {
        let session = Session(cassetteName: "upload-file")
        session.recordingEnabled = false
        let expectation = expectationWithDescription("Network")

        let data = encodeMultipartBody(NSData(contentsOfURL: testFile)!, parameters: [:])
        let file = writeDataToFile(data, fileName: "upload-file")

        session.uploadTaskWithRequest(request, fromFile: file) { data, response, error in
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String: AnyObject]
                XCTAssertEqual("test file\n", (JSON?["form"] as? [String: AnyObject])?["file"] as? String)
            } catch {
                XCTFail("Failed to read JSON.")
            }

            let HTTPResponse = response as! NSHTTPURLResponse
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }.resume()

        waitForExpectationsWithTimeout(4, handler: nil)
    }

    func testUploadData() {
        let session = Session(cassetteName: "upload-data")
        session.recordingEnabled = false
        let expectation = expectationWithDescription("Network")

        let data = encodeMultipartBody(NSData(contentsOfURL: testFile)!, parameters: [:])

        session.uploadTaskWithRequest(request, fromData: data) { data, response, error in
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String: AnyObject]
                XCTAssertEqual("test file\n", (JSON?["form"] as? [String: AnyObject])?["file"] as? String)
            } catch {
                XCTFail("Failed to read JSON.")
            }

            let HTTPResponse = response as! NSHTTPURLResponse
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }.resume()

        waitForExpectationsWithTimeout(4, handler: nil)
    }

    func testUploadDelegate() {
        class Delegate: NSObject, NSURLSessionDataDelegate {
            var task: NSURLSessionTask?
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            @objc func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
                task = dataTask
                expectation.fulfill()
            }
        }

        let expectation = expectationWithDescription("didCompleteWithError")
        let delegate = Delegate(expectation: expectation)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let backingSession = NSURLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        let session = Session(cassetteName: "upload-data", backingSession: backingSession)
        session.recordingEnabled = false

        let data = encodeMultipartBody(NSData(contentsOfURL: testFile)!, parameters: [:])

        let task = session.uploadTaskWithRequest(request, fromData: data)
        task.resume()

        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertEqual(task, delegate.task)
    }

    // MARK: Helpers

    func encodeMultipartBody(data: NSData, parameters: [String: AnyObject]) -> NSData {
        let delim = "--\(multipartBoundary)\r\n".UTF8Data()

        let body = NSMutableData()
        body += delim
        for (key, value) in parameters {
            body += "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".UTF8Data()
            body += delim
        }

        body += "Content-Disposition: form-data; name=\"file\"\r\n\r\n".UTF8Data()
        body += data
        body += "\r\n--\(multipartBoundary)--\r\n".UTF8Data()

        return body
    }

    func writeDataToFile(data: NSData, fileName: String) -> NSURL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let documentsURL = NSURL(fileURLWithPath: documentsPath, isDirectory: true)

        let url = documentsURL.URLByAppendingPathComponent(fileName + ".tmp")

        data.writeToURL(url, atomically: true)
        return url
    }

}

// MARK: - Helpers

extension String {
    func UTF8Data() -> NSData {
        return dataUsingEncoding(NSUTF8StringEncoding)!
    }
}


public func +=(lhs: NSMutableData, rhs: NSData) {
    lhs.appendData(rhs)
}
