import Foundation

// There isn't a mutable NSURLResponse, so we have to make our own.
class MutableURLResponse: URLResponse {
    private var _url: URL?
    override var url: URL? {
        get {
            return _url ?? super.url
        }

        set {
            _url = newValue
        }
    }
}


extension URLResponse {
    var dictionary: [String: Any] {
        var dictionary: [String: Any] = [:]

        dictionary["url"] = url?.absoluteString
        dictionary["mimeType"] = mimeType
        dictionary["expectedContentLength"] = expectedContentLength
        dictionary["textEncodingName"] = textEncodingName

        return dictionary
    }
}


extension URLResponse {
    convenience init?(dictionary: [String: Any]) {
        guard
            let url = (dictionary["url"] as? String).flatMap(URL.init(string:))
        else {
            return nil
        }

        let expectedContentLength = dictionary["expectedContentLength"] as? Int ?? 0
        let mimeType = dictionary["mimeType"] as? String
        let encodingName = dictionary["textEncodingName"] as? String

        self.init(url: url, mimeType: mimeType, expectedContentLength: expectedContentLength, textEncodingName: encodingName)
    }
}
