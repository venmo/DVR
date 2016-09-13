import Foundation

extension URLRequest {
    var dictionary: [String: AnyObject] {
        var dictionary = [String: AnyObject]()

        if let method = httpMethod {
            dictionary["method"] = method as AnyObject?
        }

        if let url = url?.absoluteString {
            dictionary["url"] = url as AnyObject?
        }

        if let headers = allHTTPHeaderFields {
            dictionary["headers"] = headers as AnyObject?
        }

        if let data = httpBody, let body = Interaction.encodeBody(data, headers: allHTTPHeaderFields) {
            dictionary["body"] = body as AnyObject?
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

    func requestWithBody(_ body: Data) -> URLRequest {
        var request = self
        request.httpBody = body
        return request
    }
}


extension URLRequest {
    init?(dictionary: [String: AnyObject]) {

        guard let method = dictionary["method"] else {
            print("No method in \(dictionary)")
            return nil
        }

        guard let string = dictionary["url"] as? String, let furl = URL(string: string) else {
            print("No url in \(dictionary)")
            return nil
        }

        var headers: [String: String] = [:]
        if let h = dictionary["headers"] as? [String: String] {
            headers = h
        }

        var body: Data? = nil

        if let b = dictionary["body"] as? String {
            if let d = b.data(using: .utf8) {
                body = d
            }
        }

        self.init(url: furl)
        self.httpMethod = method as? String
        self.httpBody = body
        self.allHTTPHeaderFields = headers
    }
}


extension URLRequest {
    mutating func appendHeaders(_ headers: [AnyHashable: Any]) {
        var existingHeaders = allHTTPHeaderFields ?? [:]

        headers.forEach { header in
            guard let key = header.0 as? String, let value = header.1 as? String , existingHeaders[key] == nil else {
                return
            }

            existingHeaders[key] = value
        }

        allHTTPHeaderFields = existingHeaders
    }
}
