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

    func interactionForRequest(request: NSURLRequest) -> Interaction? {
        for interaction in interactions {
            let interactionRequest = interaction.request

            // Note: We don't check headers right now
            if interactionRequest.HTTPMethod == request.HTTPMethod && interactionRequest.URL == request.URL && equalHTTPBody(request: interactionRequest, request: request) {
                return interaction
            }
        }
        return nil
    }


    // MARK: - Private

    private func equalHTTPBody(request request1: NSURLRequest, request request2: NSURLRequest) -> Bool {
        if let body1 = request1.HTTPBody,
            body2 = request2.HTTPBody,
            encoded1 = Interaction.encodeBody(body1, headers: request1.allHTTPHeaderFields),
            encoded2 = Interaction.encodeBody(body2, headers: request2.allHTTPHeaderFields) {

                return encoded1.isEqual(encoded2)
        } else {
            return request1.HTTPBody == request2.HTTPBody
        }
    }
}


extension Cassette {
    var dictionary: [String: AnyObject] {
        return [
            "name": name,
            "interactions": interactions.map { $0.dictionary }
        ]
    }

    init?(dictionary: [String: AnyObject]) {
        guard let name = dictionary["name"] as? String else { return nil }

        self.name = name

        if let array = dictionary["interactions"] as? [[String: AnyObject]] {
            interactions = array.flatMap { Interaction(dictionary: $0) }
        } else {
            interactions = []
        }
    }
}
