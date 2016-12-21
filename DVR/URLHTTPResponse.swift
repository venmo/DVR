import Foundation

// There isn't a mutable NSHTTPURLResponse, so we have to make our own.
final class MutableHTTPURLResponse: HTTPURLResponse {

    // MARK: - Properties

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


extension MutableHTTPURLResponse {
    override var dictionary: [String: Any] {
        var dictionary = super.dictionary

        dictionary["status"] = statusCode
        dictionary["headers"] = allHeaderFields

        return dictionary
    }
}


extension HTTPURLResponse {
    convenience init?(dictionary: [String: Any]) {
        guard
            let url = (dictionary["url"] as? String).flatMap(URL.init(string:)),
            let statusCode = (dictionary["status"] as? Int)
        else {
            return nil
        }

        let headerFields = dictionary["headers"] as? [String: String]

        self.init(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headerFields)
    }
}
