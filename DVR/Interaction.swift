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
            "recorded_at": recordedAt.timeIntervalSince1970
        ]
        
        var contentType: String?
        if let httpResponse = self.response as? NSHTTPURLResponse {
            contentType = httpResponse.allHeaderFields["Content-Type"] as? String
        }
        
        var response = self.response.dictionary
        if let data = responseData {
            let (format, body) = DataSerialization.serializeBodyData(data, contentType: contentType)
            response["body"] = body
            response["body_format"] = format.rawValue
        }
        dictionary["response"] = response
        
        return dictionary
    }

    init?(dictionary: [String: AnyObject]) {
        guard let request = dictionary["request"] as? [String: AnyObject],
            response = dictionary["response"] as? [String: AnyObject],
            recordedAt = dictionary["recorded_at"] as? Int else { return nil }

        self.request = NSMutableURLRequest(dictionary: request)
        self.response = URLHTTPResponse(dictionary: response)
        self.recordedAt = NSDate(timeIntervalSince1970: NSTimeInterval(recordedAt))

        if let body = response["body"] {
            let formatString = response["body_format"] as? String ?? ""
            let format = SerializationFormat(rawValue: formatString) ?? .Base64String
            self.responseData = DataSerialization.deserializeBodyData(format, object: body)
        } else {
            self.responseData = nil
        }
    }
}

