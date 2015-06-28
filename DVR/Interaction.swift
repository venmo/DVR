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

// Body data serialization
extension Interaction {
    
    // Identifies the way data was persisted on disk
    enum SerializationFormat: String {
        case JSON = "json"
        case Base64String = "base64_string" //legacy default
    }
    
    static func serializeBodyData(data: NSData) -> (format: SerializationFormat, object: AnyObject) {
        
        //try to parse and save as json to make it more readable on disk.
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: [.AllowFragments])
            return (format: .JSON, json)
        } catch { /* nope, not a valid json. nevermind. */ }
        
        //no prettier representation, fall back to base64 string
        let string = data.base64EncodedStringWithOptions([])
        return (format: .Base64String, object: string)
    }
    
    static func deserializeBodyData(format: SerializationFormat, object: AnyObject) -> NSData {
        
        switch format {
        case .JSON:
            do {
                return try NSJSONSerialization.dataWithJSONObject(object, options: [])
            } catch { fatalError("Failed to convert JSON object \(object) into data") }
            
        case .Base64String:
            return NSData(base64EncodedString: object as! String, options: [])!
        }
    }
}

extension Interaction {
    
    var dictionary: [String: AnyObject] {
        var dictionary: [String: AnyObject] = [
            "request": request.dictionary,
            "recorded_at": recordedAt.timeIntervalSince1970
        ]

        var response = self.response.dictionary
        if let data = responseData {
            let (format, body) = Interaction.serializeBodyData(data)
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
            self.responseData = Interaction.deserializeBodyData(format, object: body)
        } else {
            self.responseData = nil
        }
    }
}
