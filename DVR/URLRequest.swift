import Foundation

extension URLRequest {
    var dictionary: [String: Any] {
        var dictionary = [String: Any]()

        if let method = httpMethod {
            dictionary["method"] = method as Any?
        }

        if let url = url?.absoluteString {
            dictionary["url"] = url as Any?
        }

        if let headers = allHTTPHeaderFields {
            dictionary["headers"] = headers as Any?
        }

        if let data = httpBody, let body = Interaction.encodeBody(data, headers: allHTTPHeaderFields) {
            dictionary["body"] = body
        }

        return dictionary
    }
}


extension URLRequest {
	func appending(headers: [AnyHashable: Any]) -> URLRequest {
		guard let headers = headers as? [String: String] else { return self }

        var request = self

		for (key, value) in headers {
			request.addValue(value, forHTTPHeaderField: key)
		}

        return request
    }

	func appending(body: Data?) -> URLRequest {
		var request = self
		request.httpBody = body
		return request
	}
}


extension NSMutableURLRequest {
    convenience init(dictionary: [String: Any]) {
        self.init()

        if let method = dictionary["method"] as? String {
            httpMethod = method
        }

        if let string = dictionary["url"] as? String, let url = URL(string: string) {
            self.url = url
        }

        if let headers = dictionary["headers"] as? [String: String] {
            allHTTPHeaderFields = headers
        }

        if let body = dictionary["body"] {
            httpBody = Interaction.dencodeBody(body, headers: allHTTPHeaderFields)
        }
    }
}


extension NSMutableURLRequest {
    func appendHeaders(_ headers: [AnyHashable: Any]) {
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
