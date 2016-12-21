import Foundation

extension URLRequest {
    var dictionary: [String: Any] {
        var dictionary = [String: Any]()

        if let method = httpMethod {
            dictionary["method"] = method
        }

        if let url = url?.absoluteString {
            dictionary["url"] = url
        }

        if let headers = allHTTPHeaderFields {
            dictionary["headers"] = headers
        }

        if let data = httpBody, let body = Interaction.encodeBody(data, headers: allHTTPHeaderFields) {
            dictionary["body"] = body
        }

        return dictionary
    }
}


extension URLRequest {
    func requestByAppendingHeaders(_ headers: [AnyHashable: Any]) -> URLRequest {
        var request = self

        request.appendHeaders(headers)

        return request
    }

    mutating func appendHeaders(_ headers: [AnyHashable: Any]) {
        var existingHeaders = allHTTPHeaderFields ?? [:]

        headers.forEach { header in
            guard let key = header.0 as? String, let value = header.1 as? String, existingHeaders[key] == nil else {
                return
            }

            existingHeaders[key] = value
        }

        allHTTPHeaderFields = existingHeaders
    }
}


extension URLRequest {
    init?(dictionary: [String: Any]) {
        guard let url = (dictionary["url"] as? String).flatMap(URL.init(string:)) else {
            return nil
        }

        self.init(url: url)

        if let method = dictionary["method"] as? String {
            httpMethod = method
        }

        if let headers = dictionary["headers"] as? [String: String] {
            allHTTPHeaderFields = headers
        }

        if let body = dictionary["body"] {
            httpBody = Interaction.dencodeBody(body, headers: allHTTPHeaderFields)
        }
    }
}
