import Foundation

class URLResonse: NSURLResponse {
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
        var dictionary = [String: AnyObject]()

        if let url = URL?.absoluteString {
            dictionary["url"] = url
        }

        return dictionary
    }
}


extension URLResonse {
    convenience init(dictionary: [String: AnyObject]) {
        self.init()

        if let string = dictionary["url"] as? String, url = NSURL(string: string) {
            URL = url
        }
    }
}
