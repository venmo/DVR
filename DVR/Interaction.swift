import Foundation

struct Interaction {
    let request: NSURLRequest
    let response: NSURLResponse
    let responseData: NSData?
    let recordedAt: NSDate

    init(request: NSURLRequest, response: NSURLResponse, responseData: NSData? = nil, recordedAt: NSDate = NSDate()) {
        self.request = request
        self.response = response
        self.responseData = responseData
        self.recordedAt = recordedAt
    }
}


extension Interaction {
    var dictionary: [String: AnyObject] {
        var dictionary: [String: AnyObject] = [
            "request": request.dictionary,
            "response": response.dictionary,
            "recorded_at": recordedAt.timeIntervalSince1970
        ]

        if let string = responseData?.base64EncodedStringWithOptions([]) {
            dictionary["response_data"] = string
        }

        return dictionary
    }

    init?(dictionary: [String: AnyObject]) {
        guard let request = dictionary["request"] as? [String: AnyObject],
            response = dictionary["response"] as? [String: AnyObject],
            recordedAt = dictionary["recored_at"] as? Int else { return nil }

        self.request = NSMutableURLRequest(dictionary: request)
        self.response = URLHTTPResonse(dictionary: response)
        self.recordedAt = NSDate(timeIntervalSince1970: NSTimeInterval(recordedAt))

        if let string = dictionary["response_data"] as? String {
            self.responseData = NSData(base64EncodedString: string, options: [])
        } else {
            self.responseData = nil
        }
    }
}