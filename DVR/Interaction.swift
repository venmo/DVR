import Foundation

struct Interaction {

    // MARK: - Properties

    let request: URLRequest
    let response: Foundation.URLResponse
    let responseData: Data?
    let recordedAt: Date


    // MARK: - Initializers

    init(request: URLRequest, response: Foundation.URLResponse, responseData: Data? = nil, recordedAt: Date = Date()) {
        self.request = request
        self.response = response
        self.responseData = responseData
        self.recordedAt = recordedAt
    }


    // MARK: - Encoding

    static func encodeBody(_ body: Data, headers: [String: String]? = nil) -> AnyObject? {
        if let contentType = headers?["Content-Type"] {
            // Text
            if contentType.hasPrefix("text/") {
                // TODO: Use text encoding if specified in headers
                return NSString(data: body, encoding: String.Encoding.utf8.rawValue)
            }

            // JSON
            if contentType.hasPrefix("application/json") {
                do {
                    return try JSONSerialization.jsonObject(with: body, options: []) as AnyObject
                } catch {
                    return nil
                }
            }
        }

        // Base64
        return body.base64EncodedString(options: []) as AnyObject?
    }

    static func dencodeBody(_ body: Any?, headers: [String: String]? = nil) -> Data? {
        guard let body = body else { return nil }

        if let contentType = headers?["Content-Type"] {
            // Text
            if let string = body as? String , contentType.hasPrefix("text/") {
                // TODO: Use encoding if specified in headers
                return string.data(using: String.Encoding.utf8)
            }

            // JSON
            if contentType.hasPrefix("application/json") {
                do {
                    return try JSONSerialization.data(withJSONObject: body, options: [])
                } catch {
                    return nil
                }
            }
        }

        // Base64
        if let base64 = body as? String {
            return Data(base64Encoded: base64, options: [])
        }

        return nil
    }
}


extension Interaction {
    var dictionary: [String: Any] {
        var dictionary: [String: Any] = [
            "request": request.dictionary,
            "recorded_at": recordedAt.timeIntervalSince1970
        ]

        var response = self.response.dictionary
        if let data = responseData, let body = Interaction.encodeBody(data, headers: response["headers"] as? [String: String]) {
            response["body"] = body
        }
        dictionary["response"] = response

        return dictionary
    }

    init?(dictionary: [String: Any]) {
        guard let request = dictionary["request"] as? [String: Any],
            let response = dictionary["response"] as? [String: Any],
            let recordedAt = dictionary["recorded_at"] as? Int else { return nil }

        self.request = NSMutableURLRequest(dictionary: request) as URLRequest
        self.response = HTTPURLResponse(dictionary: response)
        self.recordedAt = Date(timeIntervalSince1970: TimeInterval(recordedAt))
        self.responseData = Interaction.dencodeBody(response["body"], headers: response["headers"] as? [String: String])
    }
}
