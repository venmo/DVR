//
//  ResponseTests.swift
//  DVR
//
//  Created by Honza Dvorsky on 28/06/2015.
//  Copyright © 2015 Venmo. All rights reserved.
//

import XCTest
@testable
import DVR

extension NSMutableURLRequest {
    
    class func createWithContentType(contentType: String, data: NSData) -> NSURLRequest {
        let request = NSMutableURLRequest()
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = contentType
        request.allHTTPHeaderFields = headers
        request.HTTPBody = data
        return request
    }
}

class RequestTests: XCTestCase {

    func testDataSerialization_JSON() {
        
        let object: NSDictionary = [
            "testing": "rules"
        ]
        let data = try! NSJSONSerialization.dataWithJSONObject(object, options: [])
        let request = NSMutableURLRequest.createWithContentType("application/json", data: data)
        let interaction = Interaction(request: request, response: NSHTTPURLResponse(), responseData: nil)
        
        let dictionary = interaction.dictionary["request"] as! NSDictionary
        XCTAssertNotNil(dictionary["body"])
        XCTAssertNotNil(dictionary["body_format"])
        XCTAssertEqual(dictionary["body"] as! NSDictionary, object)
        XCTAssertEqual(dictionary["body_format"] as! String, SerializationFormat.JSON.rawValue)
    }
    
    func testDataSerialization_PlainText() {
        
        let object: String = "testing_rules"
        let data = object.dataUsingEncoding(NSUTF8StringEncoding)!
        let request = NSMutableURLRequest.createWithContentType("text/plain", data: data)
        let interaction = Interaction(request: request, response: NSHTTPURLResponse(), responseData: nil)
        
        let dictionary = interaction.dictionary["request"] as! NSDictionary
        XCTAssertNotNil(dictionary["body"])
        XCTAssertNotNil(dictionary["body_format"])
        XCTAssertEqual(dictionary["body"] as! String, object)
        XCTAssertEqual(dictionary["body_format"] as! String, SerializationFormat.PlainText.rawValue)
    }
    
    func testDataSerialization_Base64() {
        
        let object: String = "testing_rules"
        let data = object.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64String = data.base64EncodedStringWithOptions([])
        
        let request = NSMutableURLRequest.createWithContentType("application/octet-stream", data: data)
        let interaction = Interaction(request: request, response: NSHTTPURLResponse(), responseData: nil)
        
        let dictionary = interaction.dictionary["request"] as! NSDictionary
        XCTAssertNotNil(dictionary["body"])
        XCTAssertNotNil(dictionary["body_format"])
        XCTAssertEqual(dictionary["body"] as! String, base64String)
        XCTAssertEqual(dictionary["body_format"] as! String, SerializationFormat.Base64String.rawValue)
    }
    
    func testDataDeserialization_JSON() {
        
        let json: NSDictionary = [
            "testing": "rules?"
        ]
        let request: [String: AnyObject] = [
            "body": json,
            "body_format": SerializationFormat.JSON.rawValue
        ]
        
        let dictionary: [String: AnyObject] = [
            "request": request,
            "recorded_at": 12345,
            "response": [String: AnyObject]()
        ]
        
        let interaction = Interaction(dictionary: dictionary)!
        let data = interaction.request.HTTPBody!
        let parsed = try! NSJSONSerialization.JSONObjectWithData(data, options: [.AllowFragments]) as! NSDictionary
        XCTAssertEqual(json, parsed)
    }
    
    func testDataDeserialization_PlainText() {
        
        let string = "testing_rules?"
        let request: [String: AnyObject] = [
            "body": string,
            "body_format": SerializationFormat.PlainText.rawValue
        ]
        
        let dictionary: [String: AnyObject] = [
            "request": request,
            "recorded_at": 12345,
            "response": [String: AnyObject]()
        ]
        
        let interaction = Interaction(dictionary: dictionary)!
        let requestData = interaction.request.HTTPBody!

        let parsed = NSString(data: requestData, encoding: NSUTF8StringEncoding)!
        XCTAssertEqual(string, parsed)
    }
    
    func testDataDeserialization_Base64() {
        
        let string = "testing_rules?"
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64String = data.base64EncodedStringWithOptions([])
        let request: [String: AnyObject] = [
            "body": base64String,
            "body_format": SerializationFormat.Base64String.rawValue
        ]
        
        let dictionary: [String: AnyObject] = [
            "request": request,
            "recorded_at": 12345,
            "response": [String: AnyObject]()
        ]
        
        let interaction = Interaction(dictionary: dictionary)!
        let requestData = interaction.request.HTTPBody!
        
        let parsed = NSString(data: requestData, encoding: NSUTF8StringEncoding)!
        XCTAssertEqual(string, parsed)
    }
    
    func testDataDeserialization_defaultsToBase64() {
        
        let string = "no_format_specified, so base64 is assumed!"
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64String = data.base64EncodedStringWithOptions([])
        let request: [String: AnyObject] = [
            "body": base64String
        ]
        
        let dictionary: [String: AnyObject] = [
            "request": request,
            "recorded_at": 12345,
            "response": [String: AnyObject]()
        ]
        
        let interaction = Interaction(dictionary: dictionary)!
        let requestData = interaction.request.HTTPBody!
        
        let parsed = NSString(data: requestData, encoding: NSUTF8StringEncoding)!
        XCTAssertEqual(string, parsed)
    }
    
}
