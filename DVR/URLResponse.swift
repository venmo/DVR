import Foundation

// There isn't a mutable NSURLResponse, so we have to make our own.
class URLResponse: NSURLResponse {
    private var _URL: NSURL?
    override var URL: NSURL? {
        get {
            return _URL ?? super.URL
        }

        set {
            _URL = newValue
        }
    }
}


extension NSURLResponse {
    var dictionary: [String: AnyObject] {
        if let url = URL?.absoluteString {
            return ["url": url]
        }

        return [:]
    }
}


extension URLResponse {
    convenience init(dictionary: [String: AnyObject]) {
        self.init()

        if let string = dictionary["url"] as? String, url = NSURL(string: string) {
            URL = url
        }
    }
}
