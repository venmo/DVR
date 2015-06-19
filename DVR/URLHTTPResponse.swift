import Foundation

// There isn't a mutable NSHTTPURLResponse, so we have to make our own.
class URLHTTPResonse: NSHTTPURLResponse {
    private var _URL: NSURL?
    override var URL: NSURL? {
        get {
            return _URL ?? super.URL
        }

        set {
            _URL = newValue
        }
    }

    private var _statusCode: Int?
    override var statusCode: Int {
        get {
            return _statusCode ?? super.statusCode
        }

        set {
            _statusCode = newValue
        }
    }

    private var _allHeaderFields: [NSObject : AnyObject]?
    override var allHeaderFields: [NSObject : AnyObject] {
        get {
            return _allHeaderFields ?? super.allHeaderFields
        }

        set {
            _allHeaderFields = newValue
        }
    }
}


extension URLHTTPResonse {
    override var dictionary: [String: AnyObject] {
        var dictionary = super.dictionary

        dictionary["headers"] = allHeaderFields
        dictionary["status"] = statusCode

        return dictionary
    }
}


extension URLHTTPResonse {
    convenience init(dictionary: [String: AnyObject]) {
        self.init()

        if let string = dictionary["url"] as? String, url = NSURL(string: string) {
            URL = url
        }

        if let headers = dictionary["headers"] as? [String: String] {
            allHeaderFields = headers
        }

        if let status = dictionary["status"] as? Int {
            statusCode = status
        }
    }
}
