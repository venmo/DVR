import XCTest
@testable import DVR

class SessionUploadTests: XCTestCase {
    func testUploadFile() {
        let session = Session(cassetteName: "upload-file")
        session.recordingEnabled = false
        let expectation = expectationWithDescription("Network")

        guard let testData = testData else {
            XCTFail("Failed to load test data")
            return
        }

        let bodyPart = BodyPart(name: "file", fileName: "testfile", mimeType: "text/plain", data: testData)
        let formData = FormData(bodyParts: [bodyPart], boundaryValue: multipartBoundary)

        let file = writeDataToFile(formData.data, fileName: "upload-file")

        session.uploadTaskWithRequest(request, fromFile: file) { data, response, error in
            guard let data = data else {
                XCTFail("Test returned no data")
                return
            }

            do {
                guard let JSON = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject] else {
                    XCTFail("Failed to unwrap JSON as dictionary")
                    return
                }

                guard let formData = JSON["files"] as? [String: AnyObject] else {
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

            guard let HTTPResponse = response as? NSHTTPURLResponse else {
                XCTFail("Response type was not an HTTP URL response")
                return
            }

            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }.resume()

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testUploadData() {
        let session = Session(cassetteName: "upload-data")
        session.recordingEnabled = false
        let expectation = expectationWithDescription("Network")

        guard let bodyPart = BodyPart(name: "file", value: "test file\n") else {
            XCTFail("Failed to create body part")
            return
        }

        let formData = FormData(bodyParts: [bodyPart], boundaryValue: "---------------------------3klfenalksjflkjoi9auf89eshajsnl3kjnwal")

        session.uploadTaskWithRequest(request, fromData: formData.data) { data, response, error in
            guard let data = data else {
                XCTFail("Test returned no data")
                return
            }

            do {
                guard let JSON = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject] else {
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

            guard let HTTPResponse = response as? NSHTTPURLResponse else {
                XCTFail("Response type was not an HTTP URL response")
                return
            }

            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }.resume()

        waitForExpectationsWithTimeout(1, handler: nil)
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

    private lazy var testFileURL: NSURL? = {
        guard let bundle = NSBundle.allBundles().filter({ $0.bundlePath.hasSuffix(".xctest") }).first else { return nil }
        return bundle.URLForResource("testfile", withExtension: "txt")
    }()

    private lazy var testData: NSData? = {
        guard let URL = self.testFileURL else { return nil }
        return NSData(contentsOfURL: URL)
    }()

    private let multipartBoundary = "---------------------------3klfenalksjflkjoi9auf89eshajsnl3kjnwal"

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
    func UTF8Data() -> NSData? {
        return dataUsingEncoding(NSUTF8StringEncoding)
    }
}


public func +=(lhs: NSMutableData, rhs: NSData) {
    lhs.appendData(rhs)
}
