//
//  FilterTests.swift
//  DVRTests-iOS
//
//  Created by Jáir Myree on 6/22/21.
//  Copyright © 2021 Venmo. All rights reserved.
//

import XCTest
import Foundation
import DVR

class FilterTests: XCTestCase {

    let testurl = URL(string: "http://example.com")!
    let testURL2 = URL(string: "https://httpbin.org/ip")
    let testURL3 = URL(string: "https://api.publicapis.org/entries")
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func cleanRequestWithFilter(filter: Filter) -> ((URLRequest)->(URLRequest)){
        return { request in
            var cleanRequest = request
            let dirtyHeaders = request.allHTTPHeaderFields ?? [:]
            var cleanHeaders = dirtyHeaders
            
            for key in filter.replacements.keys {
                if dirtyHeaders[key] != nil {
                    cleanHeaders[key] = filter.replacements[key]
                }
            }
            cleanRequest.allHTTPHeaderFields = cleanHeaders
            
            return cleanRequest
        }
        
        
    }
    
    func cleanResponseWithFilter(filter: Filter) -> ((URLResponse,Data?)->(URLResponse,Data?)) {
        return { response, data in
            var jsonData = try! JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]
            for key in filter.replacements.keys {
                if jsonData![key] != nil {
                    jsonData![key] = filter.replacements[key]
                }
            }
            print(JSONSerialization.isValidJSONObject(jsonData))
            return try! (response, JSONSerialization.data(withJSONObject: jsonData, options: []))
        }
    }
    
    //ensures that requests are scrubbed appropriately
    func testRequestCleanse() throws {
        var filter = Filter(replacements: ["Expires" : "Redacted", "Authorization" : "Redacted"])
        filter.beforeRecordRequest = cleanRequestWithFilter(filter: filter)
        
        let session = Session(cassetteName: "test_cassette" , filter: filter)
        
        var request = URLRequest(url: testurl)
        request.allHTTPHeaderFields = [:]
        request.allHTTPHeaderFields!["Authorization"] = "1234-5678-9000"
        print("Here")
        print(request.allHTTPHeaderFields!)
        let cleanedRequest = cleanRequestWithFilter(filter: filter)(request)
        print(cleanedRequest.allHTTPHeaderFields!)
        XCTAssert(cleanedRequest.allHTTPHeaderFields!["Authorization"]=="Redacted")
        
    }
    
    //ensures that responses are scrubbed appropriately
    func testResponseCleanse() throws {
        var filter = Filter(replacements: ["origin":"000.0.000.000"])
        filter.beforeRecordResponse = cleanResponseWithFilter(filter: filter)
        
        let session = URLSession.shared
        
        let expect = expectation(description: "wait for print")
        session.dataTask(with: testURL2!) { [self] data, urlResponse, error in
            print("here")
            if let httpResponse = urlResponse as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            let jsonData = try! JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]
            print(jsonData)
            var cleansedData = filter.beforeRecordResponse(urlResponse!, data).1
            let cleanJson = try! JSONSerialization.jsonObject(with: cleansedData!, options: []) as? [String : Any]
            XCTAssert(cleanJson!["origin"] as! String=="000.0.000.000")
            expect.fulfill()
        }.resume()
        
        waitForExpectations(timeout: 10, handler: nil)
    }

    

}
