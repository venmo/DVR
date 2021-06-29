import XCTest
import Foundation
@testable import DVR

class FilterTests: XCTestCase {

    lazy var request: URLRequest = {
        var request = URLRequest(url: URL(string: "https://www.example.com?param1=val1&param2=val2&param3=val3")!)
        request.allHTTPHeaderFields = ["Header1": "stuff1", "Header2": "stuff2", "Header3": "stuff3"]
        return request
    }()

    lazy var response: Foundation.HTTPURLResponse = {
        var response = Foundation.HTTPURLResponse(
            url: URL(string: "https://www.example/com")!,
            statusCode: 200,
            httpVersion: "",
            headerFields: ["Header1": "value1", "Header2": "value2", "Header3": "value3"]
        )
        return response!
    }()

    // ensures that requests are scrubbed appropriately
    func testRequestFilters() throws {
        var filter = Filter()
        filter.filterHeaders = [
            "header1": .remove,
            "header2": .replace("redacted"),
            "header3": .closure { key, val in
                return "\(key)+\(val!)"
            }
        ]
        filter.filterQueryParameters = [
            "param1": .remove,
            "param2": .replace("redacted"),
            "param3": .closure { key, val in
                return "\(key)\(val!)"
            }
        ]
        filter.beforeRecordRequest = { request in
            var newRequest = request
            newRequest.addValue("value4", forHTTPHeaderField: "header4")
            return newRequest
        }
        let cleanedRequest = filter.filter(request: request)
        let queryTuples = URLComponents(url: cleanedRequest.url!, resolvingAgainstBaseURL: true)!.queryItems!
        let queryItems = queryTuples.reduce(into: [:]) { $0[$1.name] = $1.value }
        XCTAssertNil(cleanedRequest.allHTTPHeaderFields!["header1"])
        XCTAssertEqual(cleanedRequest.allHTTPHeaderFields!["header2"], "redacted")
        XCTAssertEqual(cleanedRequest.allHTTPHeaderFields!["header3"], "header3+stuff3")
        XCTAssertEqual(cleanedRequest.allHTTPHeaderFields!["header4"], "value4")
        XCTAssertNil(queryItems["param1"])
        XCTAssertEqual(queryItems["param2"], "redacted")
        XCTAssertEqual(queryItems["param3"], "param3val3")
    }

    // ensures that responses are scrubbed appropriately
    func testResponseFilters() throws {
        var filter = Filter()
        filter.filterHeaders = [
            "header1": .remove,
            "header2": .replace("redacted"),
            "header3": .closure { key, val in
                return "\(key)+\(val!)"
            }
        ]
        filter.beforeRecordResponse = { response, data in
            let httpResponse = response as! Foundation.HTTPURLResponse
            var newHeaders = Dictionary(uniqueKeysWithValues: httpResponse.allHeaderFields.map { ($0 as! String, $1 as! String) })
            newHeaders["header4"] = "value4"
            let newResponse = Foundation.HTTPURLResponse(
                url: httpResponse.url!,
                statusCode: httpResponse.statusCode,
                httpVersion: "",
                headerFields: newHeaders
            )
            let newData: Data? = nil
            return (newResponse!, newData)
        }
        let (cleanedResponse, _) = filter.filter(response: response, withData: nil)!
        let headers = (cleanedResponse as! Foundation.HTTPURLResponse).allHeaderFields
        XCTAssertNil(headers["header1"])
        XCTAssertEqual(headers["header2"] as! String, "redacted")
        XCTAssertEqual(headers["header3"] as! String, "header3+value3")
        XCTAssertEqual(headers["header4"] as! String, "value4")
    }
}
