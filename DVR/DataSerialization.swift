//
//  DataSerialization.swift
//  DVR
//
//  Created by Honza Dvorsky on 04/07/2015.
//  Copyright © 2015 Venmo. All rights reserved.
//

import Foundation

// Identifies the way data was persisted on disk
enum SerializationFormat: String {
    case JSON = "json"
    case PlainText = "plain_text"
    case Base64String = "base64_string" //legacy default
}

// Body data serialization
class DataSerialization {
    
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
