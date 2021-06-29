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

    // MARK: Internal Methods

    func filterHeaders(for request: inout URLRequest) {
        // return early if request has no headers
        guard request.allHTTPHeaderFields != nil else {
            return
        }
        for (key, filter) in filterHeaders ?? [:] {
            guard let match = request.allHTTPHeaderFields![key] else {
                continue
            }
            switch filter {
            case .remove:
                request.setValue(nil, forHTTPHeaderField: key)
            case let .replace(replacement):
                request.setValue(replacement, forHTTPHeaderField: key)
            case let .closure(function):
                request.setValue(function(key, match), forHTTPHeaderField: key)
            }
        }
    }

    func filterHeaders(for response: inout Foundation.URLResponse) {
        // return early if response is not HTTPURLResponse or has no headers
        guard let httpResponse = response as? Foundation.HTTPURLResponse,
              httpResponse.allHeaderFields.isEmpty == false else {
            return
        }
        var headers = Dictionary(uniqueKeysWithValues: httpResponse.allHeaderFields.map { ($0 as! String, $1 as! String) })
        for (key, filter) in filterHeaders ?? [:] {
            guard let match = headers[key] else {
                continue
            }
            switch filter {
            case .remove:
                headers[key] = nil
            case let .replace(replacement):
                headers[key] = replacement
            case let .closure(function):
                headers[key] = function(key, match)
            }
        }
        response = Foundation.HTTPURLResponse(
            url: httpResponse.url!,
            statusCode: httpResponse.statusCode,
            httpVersion: "",
            headerFields: headers
        ) ?? response
    }

    func filterQueryParams(for request: inout URLRequest) {
        // return early if request has no query params
        guard let url = request.url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        var filteredQueryParams: [URLQueryItem] = []
        for item in queryItems {
            guard let filterMatch = filterQueryParameters?[item.name] else {
                continue
            }
            switch filterMatch {
            case .remove:
                continue
            case let .replace(replacement):
                filteredQueryParams.append(URLQueryItem(name: item.name, value: replacement))
            case let .closure(function):
                // don't add if the closure returns nil
                if let newValue = function(item.name, item.value) {
                    filteredQueryParams.append(URLQueryItem(name: item.name, value: newValue))
                }
            }
        }
        components.queryItems = filteredQueryParams
        request.url = components.url
    }

    func filterPostParams(for request: inout URLRequest) {
        // return early if request is not a POST or has no body params
        guard request.httpMethod == "POST",
              let httpBody = request.httpBody,
              var jsonBody = try? JSONSerialization.jsonObject(with: httpBody, options: [.mutableContainers]) else {
            return
        }
        // TODO: needs to account for different ways of encoding form data
    }

    func filter(request: URLRequest) -> URLRequest {
        var filtered = request
        filterHeaders(for: &filtered)
        filterQueryParams(for: &filtered)
        filterPostParams(for: &filtered)
        filtered = beforeRecordRequest?(filtered) ?? filtered
        return filtered
    }

    func filter(response: Foundation.URLResponse, withData data: Data?) -> (Foundation.URLResponse, Data?)? {
        var filtered = response
        var filteredData = data
        filterHeaders(for: &filtered)
        if let responseFilter = beforeRecordResponse {
            if let filterValues = responseFilter(filtered, filteredData) {
                filtered = filterValues.0
                filteredData = filterValues.1
            } else {
                return nil
            }
        }
        return (filtered, filteredData)
    }
}
