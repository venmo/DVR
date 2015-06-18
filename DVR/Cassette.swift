struct Cassette {
    let name: String
    let interactions: [Interaction]

    init(name: String, interactions: [Interaction]) {
        self.name = name
        self.interactions = interactions
    }
}


extension Cassette {
    var dictionary: [String: AnyObject] {
        return [
            "name": name,
            "interactions": interactions.map() { $0.dictionary }
        ]
    }

    init?(dictionary: [String: AnyObject]) {
        guard let name = dictionary["name"] as? String else { return nil }

        self.name = name

        var interactions = [Interaction]()
        if let array = dictionary["interactions"] as? [[String: AnyObject]] {
            for dictionary in array {
                if let interaction = Interaction(dictionary: dictionary) {
                    interactions.append(interaction)
                }
            }
        }
        self.interactions = interactions
    }
}
