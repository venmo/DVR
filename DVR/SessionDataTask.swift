import Foundation

class SessionDataTask: NSURLSessionDataTask {

    // MARK: - Properties

    weak var session: Session!
    let request: NSURLRequest
    let completion: ((NSData?, NSURLResponse?, NSError?) -> Void)?


    // MARK: - Initializers

    init(session: Session, request: NSURLRequest, completion: ((NSData?, NSURLResponse?, NSError?) -> Void)? = nil) {
        self.session = session
        self.request = request
        self.completion = completion
    }


    // MARK: - NSURLSessionDataTask

    override func resume() {
        let cassette = session.cassette

        // Find interaction
        if let interaction = cassette?.interactionForRequest(request) {
            // Forward completion
            completion?(interaction.responseData, interaction.response, nil)
            return
        }

		if cassette != nil {
			print("[DVR] Invalid request. The request was not found in the cassette.")
			abort()
		}

        // Cassette is missing. Record.
		if session.recordingEnabled == false {
			print("[DVR] Recording is disabled.")
			abort()
		}

        // Create directory
        let outputDirectory = session.outputDirectory.stringByExpandingTildeInPath
        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(outputDirectory) {
            try! fileManager.createDirectoryAtPath(outputDirectory, withIntermediateDirectories: true, attributes: nil)
        }

        print("[DVR] Recording '\(session.cassetteName)'")

        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            // Create cassette
            let interaction = Interaction(request: self.request, response: response!, responseData: data)
            let cassette = Cassette(name: self.session.cassetteName, interactions: [interaction])

            // Persist
            do {
                let outputPath = outputDirectory.stringByAppendingPathComponent(self.session.cassetteName).stringByAppendingPathExtension("json")!
                let data = try NSJSONSerialization.dataWithJSONObject(cassette.dictionary, options: [.PrettyPrinted])
                data.writeToFile(outputPath, atomically: true)
                print("[DVR] Persisted cassette at \(outputPath). Please add this file to your test target")
				abort()
            } catch {
                // Do nothing
            }

			print("[DVR] Failed to persist cassette.")
			abort()
        }
        task?.resume()
    }
}
