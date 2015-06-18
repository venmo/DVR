import Foundation

class SessionDataTask: NSURLSessionDataTask {

    // MARK: - Properties

    let cassettesDirectory: String
    let cassetteName: String
    let request: NSURLRequest
    let completion: ((NSData?, NSURLResponse?, NSError?) -> Void)?


    // MARK: - Initializers

    init(cassettesDirectory: String, cassetteName: String, request: NSURLRequest, completion: ((NSData?, NSURLResponse?, NSError?) -> Void)? = nil) {
        self.cassettesDirectory = cassettesDirectory
        self.cassetteName = cassetteName
        self.request = request
        self.completion = completion
    }


    // MARK: - NSURLSessionDataTask

    override func resume() {
        let cassette = self.cassette

        // Find interaction
        if let interaction = cassette?.interactionForRequest(request) {
            // Forward completion
            completion?(interaction.responseData, interaction.response, nil)
            return
        }

        // Cassette is missing. Record.
        if cassette == nil {
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request) { data, response, error in
                // Create cassette
                let interaction = Interaction(request: self.request, response: response!, responseData: data)
                let cassette = Cassette(name: self.cassetteName, interactions: [interaction])

                // Persist
                do {
                    let data = try NSJSONSerialization.dataWithJSONObject(cassette.dictionary, options: [.PrettyPrinted])
                    data.writeToFile(self.cassettePath, atomically: true)
                } catch {
                    assert(false, "Failed to persist cassette.")
                }

                // Forward completion
                self.completion?(data, response, error)
            }
            task?.resume()
        }
    }


    // MARK: - Private

    private var cassettePath: String! {
        return cassettesDirectory.stringByAppendingPathComponent(cassetteName).stringByAppendingPathExtension("json")
    }

    private var cassette: Cassette? {
        guard let data = NSData(contentsOfFile: cassettePath) else { return nil }
        do {
            if let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject] {
                return Cassette(dictionary: json)
            }
        } catch {
            return nil
        }
        return nil
    }
}
