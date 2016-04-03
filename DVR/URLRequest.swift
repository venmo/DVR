import Foundation

extension NSURLRequest {
    var dictionary: [String: AnyObject] {
        var dictionary = [String: AnyObject]()

        if let method = HTTPMethod {
            dictionary["method"] = method
        }

        if let url = URL?.absoluteString {
            dictionary["url"] = url
        }

        if let headers = allHTTPHeaderFields {
            dictionary["headers"] = headers
        }

        if let data = HTTPBody, body = Interaction.encodeBody(data, headers: allHTTPHeaderFields) {
            dictionary["body"] = body
        }

        return dictionary
    }
}


extension NSURLRequest {
    func requestByAppendingHeaders(headers: [NSObject: AnyObject]) -> NSURLRequest {
        let request = mutableCopy() as! NSMutableURLRequest
        request.appendHeaders(headers)
        return request.copy() as! NSURLRequest
    }

    func requestWithBody(body: NSData) -> NSURLRequest {
        let request = mutableCopy() as! NSMutableURLRequest
        request.HTTPBody = body
        return request.copy() as! NSURLRequest
    }
}


extension NSMutableURLRequest {
    convenience init(dictionary: [String: AnyObject]) {
        self.init()

        if let method = dictionary["method"] as? String {
            HTTPMethod = method
        }

        if let string = dictionary["url"] as? String, url = NSURL(string: string) {
            URL = url
        }

        if let headers = dictionary["headers"] as? [String: String] {
            allHTTPHeaderFields = headers
        }

        if let body = dictionary["body"] {
            HTTPBody = Interaction.dencodeBody(body, headers: allHTTPHeaderFields)
        }
    }
}


extension NSMutableURLRequest {
    func appendHeaders(headers: [NSObject: AnyObject]) {
        var existingHeaders = allHTTPHeaderFields ?? [:]

        headers.forEach { header in
            guard let key = header.0 as? String, value = header.1 as? String where existingHeaders[key] == nil else {
                return
            }

            existingHeaders[key] = value
        }

        allHTTPHeaderFields = existingHeaders
    }
}
