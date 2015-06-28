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

extension URLHTTPResponse {
    
    class func createWithContentType(contentType: String) -> URLHTTPResponse {
        let response = URLHTTPResponse()
        var headers = response.allHeaderFields
        headers["Content-Type"] = contentType
        response.allHeaderFields = headers
        return response
    }
}

class ResponseTests: XCTestCase {

    func testDataSerialization_JSON() {
        
        let object: NSDictionary = [
            "testing": "rules"
        ]
        let data = try! NSJSONSerialization.dataWithJSONObject(object, options: [])
        let response = URLHTTPResponse.createWithContentType("application/json")
        let interaction = Interaction(request: NSURLRequest(), response: response, responseData: data)
        
        let dictionary = interaction.dictionary["response"] as! NSDictionary
        XCTAssertNotNil(dictionary["body"])
        XCTAssertNotNil(dictionary["body_format"])
        XCTAssertEqual(dictionary["body"] as! NSDictionary, object)
        XCTAssertEqual(dictionary["body_format"] as! String, Interaction.SerializationFormat.JSON.rawValue)
    }
    
    func testDataSerialization_PlainText() {
        
        let object: String = "testing_rules"
        let data = object.dataUsingEncoding(NSUTF8StringEncoding)!
        let response = URLHTTPResponse.createWithContentType("text/plain")
        let interaction = Interaction(request: NSURLRequest(), response: response, responseData: data)
        
        let dictionary = interaction.dictionary["response"] as! NSDictionary
        XCTAssertNotNil(dictionary["body"])
        XCTAssertNotNil(dictionary["body_format"])
        XCTAssertEqual(dictionary["body"] as! String, object)
        XCTAssertEqual(dictionary["body_format"] as! String, Interaction.SerializationFormat.PlainText.rawValue)
    }
    
    func testDataSerialization_Base64() {
        
        let object: String = "testing_rules"
        let data = object.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64String = data.base64EncodedStringWithOptions([])
        
        let response = URLHTTPResponse.createWithContentType("application/octet-stream")
        let interaction = Interaction(request: NSURLRequest(), response: response, responseData: data)
        
        let dictionary = interaction.dictionary["response"] as! NSDictionary
        XCTAssertNotNil(dictionary["body"])
        XCTAssertNotNil(dictionary["body_format"])
        XCTAssertEqual(dictionary["body"] as! String, base64String)
        XCTAssertEqual(dictionary["body_format"] as! String, Interaction.SerializationFormat.Base64String.rawValue)
    }
    
    func testDataDeserialization_JSON() {
        
        let json: NSDictionary = [
            "testing": "rules?"
        ]
        let response: [String: AnyObject] = [
            "body": json,
            "body_format": Interaction.SerializationFormat.JSON.rawValue
        ]
        
        let dictionary: [String: AnyObject] = [
            "request": [String: AnyObject](),
            "recorded_at": 12345,
            "response": response
        ]
        
        let interaction = Interaction(dictionary: dictionary)!
        let data = interaction.responseData!
        let parsed = try! NSJSONSerialization.JSONObjectWithData(data, options: [.AllowFragments]) as! NSDictionary
        XCTAssertEqual(json, parsed)
    }
    
    func testDataDeserialization_PlainText() {
        
        let string = "testing_rules?"
        let response: [String: AnyObject] = [
            "body": string,
            "body_format": Interaction.SerializationFormat.PlainText.rawValue
        ]
        
        let dictionary: [String: AnyObject] = [
            "request": [String: AnyObject](),
            "recorded_at": 12345,
            "response": response
        ]
        
        let interaction = Interaction(dictionary: dictionary)!
        let responseData = interaction.responseData!
        
        let parsed = NSString(data: responseData, encoding: NSUTF8StringEncoding)!
        XCTAssertEqual(string, parsed)
    }
    
    func testDataDeserialization_Base64() {
        
        let string = "testing_rules?"
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64String = data.base64EncodedStringWithOptions([])
        let response: [String: AnyObject] = [
            "body": base64String,
            "body_format": Interaction.SerializationFormat.Base64String.rawValue
        ]
        
        let dictionary: [String: AnyObject] = [
            "request": [String: AnyObject](),
            "recorded_at": 12345,
            "response": response
        ]
        
        let interaction = Interaction(dictionary: dictionary)!
        let responseData = interaction.responseData!
        
        let parsed = NSString(data: responseData, encoding: NSUTF8StringEncoding)!
        XCTAssertEqual(string, parsed)
    }
    
    func testDataDeserialization_defaultsToBase64() {
        
        let string = "no_format_specified, so base64 is assumed!"
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64String = data.base64EncodedStringWithOptions([])
        let response: [String: AnyObject] = [
            "body": base64String
        ]
        
        let dictionary: [String: AnyObject] = [
            "request": [String: AnyObject](),
            "recorded_at": 12345,
            "response": response
        ]
        
        let interaction = Interaction(dictionary: dictionary)!
        let responseData = interaction.responseData!
        
        let parsed = NSString(data: responseData, encoding: NSUTF8StringEncoding)!
        XCTAssertEqual(string, parsed)
    }
    
}
