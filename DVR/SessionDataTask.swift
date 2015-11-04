import Foundation

class SessionDataTask: NSURLSessionDataTask {

    // MARK: - Types

    typealias Completion = (NSData?, NSURLResponse?, NSError?) -> Void


    // MARK: - Properties

    weak var session: Session!
    let request: NSURLRequest
    let completion: Completion?
    private let queue = dispatch_queue_create("com.venmo.DVR.sessionDataTaskQueue", nil)


    // MARK: - Initializers

    init(session: Session, request: NSURLRequest, completion: (Completion)? = nil) {
        self.session = session
        self.request = request
        self.completion = completion
    }


    // MARK: - NSURLSessionTask
    
    override func cancel() {
        // Don't do anything
    }

    override func resume() {
        let cassette = session.cassette

        // Find interaction
        if let interaction = cassette?.interactionForRequest(request) {
            // Forward completion
            if let completion = completion {
                print("[DVR] Replaying '\(session.cassetteName)'")
                dispatch_async(queue) {
                    completion(interaction.responseData, interaction.response, nil)
                }
            }
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
        let outputDirectory = (session.outputDirectory as NSString).stringByExpandingTildeInPath
        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(outputDirectory) {
            try! fileManager.createDirectoryAtPath(outputDirectory, withIntermediateDirectories: true, attributes: nil)
        }

        print("[DVR] Recording '\(session.cassetteName)'")

        let task = session.backingSession.dataTaskWithRequest(request) { data, response, error in
            
            //Ensure we have a response
            guard let response = response else {
                print("[DVR] Failed to persist cassette, because the task returned a nil response.")
                abort()
            }
            
            // Create cassette
            let interaction = Interaction(request: self.request, response: response, responseData: data)
            let cassette = Cassette(name: self.session.cassetteName, interactions: [interaction])

            // Persist
            do {
                let outputPath = ((outputDirectory as NSString).stringByAppendingPathComponent(self.session.cassetteName) as NSString).stringByAppendingPathExtension("json")!
                let data = try NSJSONSerialization.dataWithJSONObject(cassette.dictionary, options: [.PrettyPrinted])

                // Add trailing new line
                guard var string = NSString(data: data, encoding: NSUTF8StringEncoding) else {
                    print("[DVR] Failed to persist cassette.")
                    abort()
                }
                string = string.stringByAppendingString("\n")

                if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
                    data.writeToFile(outputPath, atomically: true)
                    print("[DVR] Persisted cassette at \(outputPath). Please add this file to your test target")
                    abort()
                }

                print("[DVR] Failed to persist cassette.")
                abort()
            } catch {
                // Do nothing
            }

			print("[DVR] Failed to persist cassette.")
            abort()
        }
        task.resume()
    }
}
