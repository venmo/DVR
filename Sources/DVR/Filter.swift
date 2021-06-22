// --------------------------------------------------------------------------
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//
// The MIT License (MIT)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the ""Software""), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
// --------------------------------------------------------------------------

import Foundation

public struct Filter {
    public var headers : [String : String]
    public var queryParameters : [String : String]
    public var postDataParameters : [String : String]
    public var beforeRecordResponse : ((Foundation.URLResponse, Data?) -> (Foundation.URLResponse, Data?))
    public var beforeRecordRequest : ((URLRequest) -> (URLRequest))
    
    public init(headers: [String] = [], queryParameters: [String] = [], postDataParameters: [String] = [], replacementString: String = "Redacted", requestHook : @escaping ((URLRequest) -> (URLRequest)) = { return $0 } , responseHook : @escaping ((Foundation.URLResponse, Data?) -> (Foundation.URLResponse, Data?)) = {return ($0, $1)} ) {
        var adjustedHeaders : [String : String] = [:]
        var adjustedQueryParameters : [String : String] = [:]
        var adjustedPostDataParameters : [String : String] = [:]
        
        for header in headers {
            adjustedHeaders[header] =  replacementString
        }
        
        for queryParam in queryParameters {
            adjustedQueryParameters[queryParam] = replacementString
        }
        
        for postDataParam in postDataParameters {
            adjustedPostDataParameters[postDataParam] = replacementString
        }
        
        self.headers = adjustedHeaders
        self.queryParameters = adjustedQueryParameters
        self.postDataParameters = adjustedPostDataParameters
        self.beforeRecordRequest = requestHook
        self.beforeRecordResponse = responseHook
    }
    
    public init(headers: [String:String] = [:], queryParameters: [String:String] = [:], postDataParameters: [String:String] = [:], requestHook : @escaping ((URLRequest) -> (URLRequest)) = {return $0} , responseHook : @escaping ((Foundation.URLResponse, Data?) -> (Foundation.URLResponse, Data?)) = {return ($0, $1) } ) {
        self.headers = headers
        self.queryParameters = queryParameters
        self.postDataParameters = postDataParameters
        self.beforeRecordRequest = requestHook
        self.beforeRecordResponse = responseHook
    }
   
}
