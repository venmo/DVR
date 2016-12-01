import XCTest
import DVR

class SessionUploadTests: XCTestCase {

    lazy var request: URLRequest = {
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"

        let contentType = "multipart/form-data; boundary=\(self.multipartBoundary)"
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        return request as URLRequest
    }()
    let multipartBoundary = "---------------------------3klfenalksjflkjoi9auf89eshajsnl3kjnwal".utf8Data
    lazy var testFile: URL = {
        return Bundle(for: type(of: self)).url(forResource: "testfile", withExtension: "txt")!
    }()

    func testUploadFile() {
        let session = Session(cassetteName: "upload-file")
        session.recordingEnabled = false
        let expectation = self.expectation(description: "Network")

        let data = encodeMultipartBody(try! Data(contentsOf: testFile), parameters: [:])
        let file = writeDataToFile(data, fileName: "upload-file")

        session.uploadTask(with: request, fromFile: file, completionHandler: { data, response, error in
            do {
                let JSON = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                XCTAssertEqual("test file\n", (JSON?["form"] as? [String: Any])?["file"] as? String)
            } catch {
                XCTFail("Failed to read JSON.")
            }

            let HTTPResponse = response as! HTTPURLResponse
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }) .resume()

        waitForExpectations(timeout: 4, handler: nil)
    }

    func testUploadData() {
        let session = Session(cassetteName: "upload-data")
        session.recordingEnabled = false
        let expectation = self.expectation(description: "Network")

        let data = encodeMultipartBody(try! Data(contentsOf: testFile), parameters: [:])

        session.uploadTask(with: request, from: data) { data, response, error in
            do {
                let JSON = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                XCTAssertEqual("test file\n", (JSON?["form"] as? [String: Any])?["file"] as? String)
            } catch {
                XCTFail("Failed to read JSON.")
            }

            let HTTPResponse = response as! HTTPURLResponse
            XCTAssertEqual(200, HTTPResponse.statusCode)

            expectation.fulfill()
        }.resume()

        waitForExpectations(timeout: 4, handler: nil)
    }


    // MARK: Helpers

    private func encodeMultipartBody(_ data: Data, parameters: [String: Any]) -> Data {
        let delim = "--\(multipartBoundary)\r\n".utf8Data

        let body = NSMutableData()
        body += delim
        for (key, value) in parameters {
            body += "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".utf8Data
            body += delim
        }

        body += "Content-Disposition: form-data; name=\"file\"\r\n\r\n".utf8Data
        body += data
        body += "\r\n--\(multipartBoundary)--\r\n".utf8Data

        return body as Data
    }

    private func writeDataToFile(_ data: Data, fileName: String) -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let documentsURL = URL(fileURLWithPath: documentsPath, isDirectory: true)
		let url = documentsURL.appendingPathComponent(fileName + ".tmp")

        try? data.write(to: url, options: [.atomic])
        return url
    }

}


// MARK: - Helpers

extension String {
	fileprivate var utf8Data: Data {
        return data(using: String.Encoding.utf8)!
    }
}


public func +=(lhs: NSMutableData, rhs: Data) {
    lhs.append(rhs)
}
