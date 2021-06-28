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

/// Filters to redact senstive information or otherwise manipulate the request/response.
public struct Filter {

    /// Describes the desired filter behavior
    public enum FilterBehavior {
        /// Value is completed ommitted
        case remove
        /// Value is replaced with a static string
        case replace(String)
        /// Value is determined by a closure which accepts the key and value and can return a new value or nil to omit
        case closure((String, String?) -> (String?))
    }

    /// filters to apply to headers
    public var filterHeaders: [String: FilterBehavior]?
    /// filters to apply to query parameters
    public var filterQueryParameters: [String: FilterBehavior]?
    /// filters to apply to post data parameters
    public var filterPostDataParameters: [String: FilterBehavior]?
    /// a closure to call when processing each response
    public var beforeRecordResponse: ((Foundation.URLResponse, Data?) -> (Foundation.URLResponse, Data?)?)?
    /// a closure to call when processing each request
    public var beforeRecordRequest: ((URLRequest) -> (URLRequest))?
    
    public init() {}
}
