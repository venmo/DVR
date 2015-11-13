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
            if interactionRequest.HTTPMethod == request.HTTPMethod && interactionRequest.URL == request.URL && interactionRequest.hasHTTPBodyEqualToThatOfRequest(request)  {
                return interaction
            }
        }
        return nil
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

private extension NSURLRequest {
    func hasHTTPBodyEqualToThatOfRequest(request: NSURLRequest) -> Bool {
        guard let body1 = self.HTTPBody,
            body2 = request.HTTPBody,
            encoded1 = Interaction.encodeBody(body1, headers: self.allHTTPHeaderFields),
            encoded2 = Interaction.encodeBody(body2, headers: request.allHTTPHeaderFields)
		else {
			return self.HTTPBody == request.HTTPBody
		}

		return encoded1.isEqual(encoded2)
    }
}
