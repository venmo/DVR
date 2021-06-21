//
//  Filter.swift
//  DVR
//
//  Created by Jáir Myree on 6/18/21.
//  Copyright © 2021 Venmo. All rights reserved.
//

import Foundation

public struct Filter {
    var headers : [String : String]
    var queryParameters : [String : String]
    var postDataParameters : [String : String]
    var beforeRecordResponse : ((inout Foundation.URLResponse, inout Data) -> ())
    var beforeRecordRequest : ((inout URLRequest) -> ())
    
    public init(headers: [String] = [], queryParameters: [String] = [], postDataParameters: [String] = [], replacer: String = "Redacted", requestHook : @escaping ((inout URLRequest) -> ()) = {_ in } , responseHook : @escaping ((inout Foundation.URLResponse, inout Data) -> ()) = {_,_  in } ) {
        var adjustedHeaders : [String : String] = [:]
        var adjustedQueryParameters : [String : String] = [:]
        var adjustedPostDataParameters : [String : String] = [:]
        
        for header in headers {
            adjustedHeaders[header] =  replacer
        }
        
        for queryParam in queryParameters {
            adjustedQueryParameters[queryParam] = replacer
        }
        
        for postDataParam in postDataParameters {
            adjustedPostDataParameters[postDataParam] = replacer
        }
        
        self.headers = adjustedHeaders
        self.queryParameters = adjustedQueryParameters
        self.postDataParameters = adjustedPostDataParameters
        self.beforeRecordRequest = requestHook
        self.beforeRecordResponse = responseHook
    }
    
    init(headers: [String:String] = [:], queryParameters: [String:String] = [:], postDataParameters: [String:String] = [:], requestHook : @escaping ((inout URLRequest) -> ()) = {_ in } , responseHook : @escaping ((inout Foundation.URLResponse, inout Data) -> ()) = {_,_ in } ) {
        self.headers = headers
        self.queryParameters = queryParameters
        self.postDataParameters = postDataParameters
        self.beforeRecordRequest = requestHook
        self.beforeRecordResponse = responseHook
    }
    
    func setFilter() {
        
    }
    
    func setPre() {
        
    }
    
}
