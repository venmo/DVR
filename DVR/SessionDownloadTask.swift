class SessionDownloadTask: NSURLSessionDownloadTask {

    // MARK: - Types

    typealias Completion = (NSURL?, NSURLResponse?, NSError?) -> Void

    // MARK: - Properties

    weak var session: Session!
    let request: NSURLRequest
    let completion: Completion?


    // MARK: - Initializers

    init(session: Session, request: NSURLRequest, completion: Completion? = nil) {
        self.session = session
        self.request = request
        self.completion = completion
    }

    // MARK: - NSURLSessionTask

    override func cancel() {
        // Don't do anything
    }

    override func resume() {
        let task = SessionDataTask(session: session, request: request) { data, response, error in
            let location: NSURL?
            if let data = data {
                // Write data to temporary file
                let tempURL = NSURL(fileURLWithPath: (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(NSUUID().UUIDString))
                data.writeToURL(tempURL, atomically: true)
                location = tempURL
            } else {
                location = nil
            }

            self.completion?(location, response, error)
        }
        task.resume()
    }
}
