import Foundation

// There isn't a mutable NSURLResponse, so we have to make our own.
open class URLResponse: Foundation.URLResponse {
    fileprivate var _URL: Foundation.URL?
    override open var url: Foundation.URL? {
        get {
            return _URL ?? super.url
        }

        set {
            _URL = newValue
        }
    }
}


extension Foundation.URLResponse {
    var dictionary: [String: AnyObject] {
        if let url = url?.absoluteString {
            return ["url": url as AnyObject]
        }

        return [:]
    }
}


extension URLResponse {
    convenience init(dictionary: [String: AnyObject]) {
        self.init()

        if let string = dictionary["url"] as? String, let furl = Foundation.URL(string: string) {
            url = furl
        }
    }
}
