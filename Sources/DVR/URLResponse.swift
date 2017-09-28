import Foundation

// There isn't a mutable URLResponse, so we have to make our own.
class URLResponse: Foundation.URLResponse {
    private var _URL: Foundation.URL?
    override var url: Foundation.URL? {
        get {
            return _URL ?? super.url
        }

        set {
            _URL = newValue
        }
    }
}


extension Foundation.URLResponse {
    var dictionary: [String: Any] {
        if let url = url?.absoluteString {
            return ["url": url as Any]
        }

        return [:]
    }
}


extension URLResponse {
    convenience init(dictionary: [String: Any]) {
        self.init()

        if let string = dictionary["url"] as? String, let url = Foundation.URL(string: string) {
            self.url = url
        }
    }
}
