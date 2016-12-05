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

    func interactionForRequest(_ request: URLRequest, ignoreBaseURL: Bool) -> Interaction? {
        for interaction in interactions {
            let interactionRequest = interaction.request

            guard let interactionURL = interactionRequest.url,
                let requestURL = request.url else {
                return nil
            }
            // Note: We don't check headers right now
            if interactionRequest.httpMethod == request.httpMethod && interactionURL.isEqual(to: requestURL, ignoreBaseURL: ignoreBaseURL) && interactionRequest.hasHTTPBodyEqualToThatOfRequest(request)  {
                return interaction
            }
        }
        return nil
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
            interactions = array.flatMap { Interaction(dictionary: $0) }
        } else {
            interactions = []
        }
    }
}

private extension URL {
    /**
     Method used to check if it is equal with the provided url.
     
     - parameter url:           The url to compare against.
     - parameter ignoreBaseURL: Bool flag for ignoring the baseURL when comparing against the provided url.
     
     - returns: true if is equal with the provided url, false otherwhise.
     */
    func isEqual(to url: URL, ignoreBaseURL: Bool = false) -> Bool {
        if ignoreBaseURL {
            return self.relativePath == url.relativePath
        } else {
            return self == url
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
}
