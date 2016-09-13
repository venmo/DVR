import Foundation

// There isn't a mutable NSHTTPURLResponse, so we have to make our own.
class URLHTTPResponse: HTTPURLResponse {

    // MARK: - Properties

    fileprivate var _URL: Foundation.URL?
    override var url: Foundation.URL? {
        get {
            return _URL ?? super.url
        }

        set {
            _URL = newValue
        }
    }

    fileprivate var _statusCode: Int?
    override var statusCode: Int {
        get {
            return _statusCode ?? super.statusCode
        }

        set {
            _statusCode = newValue
        }
    }

    fileprivate var _allHeaderFields: [AnyHashable: Any]?
    override var allHeaderFields: [AnyHashable: Any] {
        get {
            return _allHeaderFields ?? super.allHeaderFields
        }

        set {
            _allHeaderFields = newValue
        }
    }
}


extension URLHTTPResponse {
    override var dictionary: [String: AnyObject] {
        var dictionary: [String: AnyObject] = super.dictionary

        dictionary["headers"] = allHeaderFields as AnyObject
        dictionary["status"] = statusCode as AnyObject

        return dictionary
    }
}


extension URLHTTPResponse {
    convenience init?(dictionary: [String: AnyObject]) {
        var durl: Foundation.URL
        if let string = dictionary["url"] as? String, let furl = Foundation.URL(string: string) {
            durl = furl
        } else {
            fatalError("Can't initialise response without URL")
        }

        var allHeaders = [String:String]()
        if let headers = dictionary["headers"] as? [String: String] {
            allHeaders = headers
        }

        var code: Int
        if let status = dictionary["status"] as? Int {
            code = status
        } else {
            fatalError("Can't initialize response without status code")
        }

        self.init(url: durl, statusCode: code, httpVersion: nil, headerFields: allHeaders)
    }
}
