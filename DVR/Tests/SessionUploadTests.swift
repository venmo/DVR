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
    lazy var testFile: NSURL? = {
        return NSBundle(forClass: self.dynamicType).URLForResource("testfile", withExtension: "txt")
    }()

    func testUploadFile() {
        let session = Session(cassetteName: "upload-file")
        session.recordingEnabled = false
        let expectation = expectationWithDescription("Network")

        guard let testFile = testFile else { XCTFail("Missing test file URL"); return }
        guard let fileData = NSData(contentsOfURL: testFile) else { XCTFail("Missing body data"); return }
        let data = encodeMultipartBody(fileData, parameters: [:])
        let file = writeDataToFile(data, fileName: "upload-file")

        session.uploadTaskWithRequest(request, fromFile: file) { data, response, error in
            if let error = error {
                XCTFail("Error uploading file: \(error)")
                return
            }
            guard let data = data else { XCTFail("Missing request data"); return }

            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject]
                XCTAssertEqual("test file\n", (JSON?["form"] as? [String: AnyObject])?["file"] as? String)
            } catch {
                XCTFail("Failed to read JSON.")
            }

            guard let HTTPResponse = response as? NSHTTPURLResponse else { XCTFail("Bad HTTP response"); return }
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }.resume()

        waitForExpectationsWithTimeout(4, handler: nil)
    }

    func testUploadData() {
        let session = Session(cassetteName: "upload-data")
        session.recordingEnabled = false
        let expectation = expectationWithDescription("Network")

        guard let testFile = testFile else { XCTFail("Missing testfile URL"); return }
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
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(documentsURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Failed to create documents directory \(documentsURL). Error \(error)")
        }

        guard let url = documentsURL.URLByAppendingPathComponent(fileName + ".tmp") else {
            XCTFail("Failed to write to file")
            fatalError()
        }

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
