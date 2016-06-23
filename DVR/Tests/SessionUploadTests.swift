import XCTest
@testable import DVR

class SessionUploadTests: XCTestCase {
    func testUploadFile() {
        let session = Session(cassetteName: "upload-file")
        session.recordingEnabled = false
        let expectation = expectationWithDescription("Network")

        let data = encodeMultipartBody(testData, parameters: [:])
        let file = writeDataToFile(data, fileName: "upload-file")

        session.uploadTaskWithRequest(request, fromFile: file) { data, response, error in
            do {
                guard let JSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String: AnyObject] else {
                    XCTFail("Failed to unwrap JSON as dictionary")
                    return
                }

                guard let formData = JSON["form"] as? [String: AnyObject] else {
                    XCTFail("Failed to unwrap form data as dictionary")
                    return
                }

                guard let formFileContents = formData["file"] as? String else {
                    XCTFail("Failed to unwrap form file contents as string")
                    return
                }

                XCTAssertEqual("test file\n", formFileContents)
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

        let data = encodeMultipartBody(testData, parameters: [:])

        session.uploadTaskWithRequest(request, fromData: data) { data, response, error in
            do {
                guard let JSON = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String: AnyObject] else {
                    XCTFail("Failed to unwrap JSON as dictionary")
                    return
                }

                guard let formData = JSON["form"] as? [String: AnyObject] else {
                    XCTFail("Failed to unwrap form data as dictionary")
                    return
                }

                guard let formFileContents = formData["file"] as? String else {
                    XCTFail("Failed to unwrap form file contents as string")
                    return
                }

                XCTAssertEqual("test file\n", formFileContents)
            } catch {
                XCTFail("Failed to read JSON.")
            }

            let HTTPResponse = response as! NSHTTPURLResponse
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }.resume()

        waitForExpectationsWithTimeout(4, handler: nil)
    }
    

    // MARK: Helpers

    private lazy var request: NSURLRequest = {
        let url = NSURL(string: "https://httpbin.org/post")!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"

        let contentType = "multipart/form-data; boundary=\(self.multipartBoundary)"
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        return request
    }()

    private lazy var testFileURL: NSURL = {
        return NSBundle(forClass: self.dynamicType).URLForResource("testfile", withExtension: "txt")!
    }()

    private lazy var testData: NSData = {
        return NSData(contentsOfURL: self.testFileURL)!
    }()

    private let multipartBoundary = "---------------------------3klfenalksjflkjoi9auf89eshajsnl3kjnwal".UTF8Data()

    private func encodeMultipartBody(data: NSData, parameters: [String: AnyObject]) -> NSData {
        let delimiter = "--\(multipartBoundary)\r\n".UTF8Data()

        let body = NSMutableData()
        body += delimiter
        for (key, value) in parameters {
            body += "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".UTF8Data()
            body += delimiter
        }

        body += "Content-Disposition: form-data; name=\"file\"\r\n\r\n".UTF8Data()
        body += data
        body += "\r\n--\(multipartBoundary)--\r\n".UTF8Data()

        return body
    }

    private func writeDataToFile(data: NSData, fileName: String) -> NSURL {
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
