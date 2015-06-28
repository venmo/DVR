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
            let (format, body) = Interaction.serializeBodyData(data, contentType: contentType)
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

// Body data serialization
extension Interaction {
    
    // Identifies the way data was persisted on disk
    enum SerializationFormat: String {
        case JSON = "json"
        case PlainText = "plain_text"
        case Base64String = "base64_string" //legacy default
    }
    
    static func serializeBodyData(data: NSData, contentType: String?) -> (format: SerializationFormat, object: AnyObject) {
        
        //JSON
        if let contentType = contentType where contentType.hasPrefix("application/json") {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: [.AllowFragments])
                return (format: .JSON, json)
            } catch { /* nope, not a valid json. nevermind. */ }
        }
        
        //Plain Text
        if let contentType = contentType where contentType.hasPrefix("text") {
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                return (format: .PlainText, object: string)
            }
        }
        
        //nope, might be image data or something else
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
        case .PlainText:
            return (object as! String).dataUsingEncoding(NSUTF8StringEncoding)!
        case .Base64String:
            return NSData(base64EncodedString: object as! String, options: [])!
        }
    }
}
