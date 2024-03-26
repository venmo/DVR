import Foundation

struct Cassette {

    // MARK: - Properties

    let name: String
    let interactions: [Interaction]


    // MARK: - Initializers

    init(name: String, interactions: [Interaction]) {
        self.name = name
        self.interactions = interactions
    }


    // MARK: - Functions

    func interactionForRequest(_ request: URLRequest, headersToCheck: [String] = [], paramsToIgnore: [String] = []) -> Interaction? {
        var match: Interaction?
        for interaction in interactions {
            let interactionRequest = interaction.request

            if interactionRequest.httpMethod == request.httpMethod &&
                interactionRequest.hasParamsEqualToThatOfRequest(request, ignoreParams: paramsToIgnore) &&
                interactionRequest.hasHTTPBodyEqualToThatOfRequest(request)  {

                // Overwrite the current match if the required headers are equal.
                if match == nil ||
                    interactionRequest.hasHeadersEqualToThatOfRequest(request, headersToCheck: headersToCheck) {
                    match = interaction
                }
            }
        }
        return match
    }
}


extension Cassette {
    var dictionary: [String: Any] {
        return [
            "name": name as Any,
            "interactions": interactions.map { $0.dictionary }
        ]
    }

    init?(dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String else { return nil }

        self.name = name

        if let array = dictionary["interactions"] as? [[String: Any]] {
            interactions = array.compactMap { Interaction(dictionary: $0) }
        } else {
            interactions = []
        }
    }
}

private extension URLRequest {
    func hasHTTPBodyEqualToThatOfRequest(_ request: URLRequest) -> Bool {
        guard let body1 = self.httpBody,
            let body2 = request.httpBody,
            let encoded1 = Interaction.encodeBody(body1, headers: self.allHTTPHeaderFields),
            let encoded2 = Interaction.encodeBody(body2, headers: request.allHTTPHeaderFields)
        else {
            return self.httpBody == request.httpBody
        }

        return encoded1.isEqual(encoded2)
    }

    func hasHeadersEqualToThatOfRequest(_ request: URLRequest, headersToCheck: [String]) -> Bool {
        let request1Headers = allHTTPHeaderFields ?? [:]
        let request2Headers = request.allHTTPHeaderFields ?? [:]
        for header in headersToCheck {
            if request1Headers[header] != request2Headers[header] {
                return false
            }
        }
        return true
    }
    
    func hasParamsEqualToThatOfRequest(_ request: URLRequest, ignoreParams: [String] = []) -> Bool {
        if url == request.url { return true }
            
        let request1 = createRequest(withoutKeys: ignoreParams)
        let request2 = request.createRequest(withoutKeys: ignoreParams)
        
        if request1.url == request2.url { return true }
        
        return false
    }

    func createRequest(withoutKeys: [String]) -> URLRequest {
        var newRequest = self
        guard let oldURL = url else { return newRequest }
        
        if var urlComponents = URLComponents(url: oldURL, resolvingAgainstBaseURL: false) {
            urlComponents.queryItems = urlComponents.queryItems?.filter {  !withoutKeys.contains($0.name) }
            newRequest.url = urlComponents.url
        }
        
        return newRequest
    }
}
