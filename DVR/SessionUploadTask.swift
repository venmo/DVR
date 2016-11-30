class SessionUploadTask: NSURLSessionUploadTask {

    // MARK: - Types

    typealias Completion = (NSData?, NSURLResponse?, NSError?) -> Void

    // MARK: - Properties

    weak var session: Session!
    let request: NSURLRequest
    let completion: Completion?
    var dataTask: SessionDataTask!

    override var response: NSURLResponse? {
        return dataTask.interaction?.response
    }

    override var taskIdentifier: Int {
        return dataTask.taskIdentifier
    }

    // MARK: - Initializers

    init(session: Session, request: NSURLRequest, completion: Completion? = nil) {
        self.session = session
        self.request = request
        self.completion = completion
        super.init()
        dataTask = SessionDataTask(session: session, request: request, backingTask: self, completion: completion)
    }

    // MARK: - NSURLSessionTask

    override func cancel() {
        // Don't do anything
    }

    override func resume() {
        dataTask.resume()
    }
}
