import Foundation

struct Cassette {
    let name: String
    let interactions: [Interaction]

    init(name: String, interactions: [Interaction]) {
        self.name = name
        self.interactions = interactions
    }

    func interactionForRequest(request: NSURLRequest) -> Interaction? {
        for interaction in interactions {
            let r = interaction.request

            // Note: We don't check headers right now
            if r.HTTPMethod == request.HTTPMethod && r.URL == request.URL && r.HTTPBody == request.HTTPBody {
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
