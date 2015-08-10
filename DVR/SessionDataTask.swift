import Foundation

class SessionDataTask: NSURLSessionDataTask {
    
    // MARK: - Types
    
    typealias Completion = (NSData?, NSURLResponse?, NSError?) -> Void
    
    
    // MARK: - Properties
    
    weak var session: Session!
    let request: NSURLRequest
    let completion: Completion?
    
    
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
            
            // Check if it's within the valid status code range
            let response = interaction.response as! NSHTTPURLResponse
            if (self.validResponse(response)) {
                completion?(interaction.responseData, response, nil)
            }
            else
            {
                let error = NSError(domain: (request.URL?.absoluteString)!, code: response.statusCode, userInfo: nil)
                completion?(nil, interaction.response, error)
            }
            
            return
        }
        
        if cassette != nil {
            fatalError("[DVR] Invalid request. The request was not found in the cassette.")
        }
        
        // Cassette is missing. Record.
        if session.recordingEnabled == false {
            fatalError("[DVR] Recording is disabled.")
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
                fatalError("[DVR] Failed to persist cassette, because the task returned a nil response.")
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
                    fatalError("[DVR] Failed to persist cassette.")
                }
                string = string.stringByAppendingString("\n")

                if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
                    data.writeToFile(outputPath, atomically: true)
                    fatalError("[DVR] Persisted cassette at \(outputPath). Please add this file to your test target")
                }

                fatalError("[DVR] Failed to persist cassette.")
            } catch {
                // Do nothing
            }
            
            fatalError("[DVR] Failed to persist cassette.")
        }
        task.resume()
    }
    
    private func validResponse(response: NSHTTPURLResponse) -> Bool {
        switch response.statusCode {
        case 304: return true
        case 200..<300: return true
        default : return false
        }
    }
}
