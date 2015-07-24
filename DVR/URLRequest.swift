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

        var contentType: String?
        if let headers = allHTTPHeaderFields {
            dictionary["headers"] = headers
            contentType = headers["Content-Type"]
        }

        if let body = HTTPBody {
            let (format, bodyObject) = DataSerialization.serializeBodyData(body, contentType: contentType)
            dictionary["body"] = bodyObject
            dictionary["body_format"] = format.rawValue
        }

        return dictionary
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
            let formatString = dictionary["body_format"] as? String ?? ""
            let format = SerializationFormat(rawValue: formatString) ?? .Base64String
            HTTPBody = DataSerialization.deserializeBodyData(format, object: body)
        }
    }
}
