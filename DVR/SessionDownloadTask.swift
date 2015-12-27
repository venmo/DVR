class SessionDownloadTask: NSURLSessionDownloadTask {

    // MARK: - Types

    typealias Completion = (NSURL?, NSURLResponse?, NSError?) -> Void

    // MARK: - Properties

    weak var session: Session!
    let request: NSURLRequest
    let completion: Completion?

    // MARK: - Overridden Properties

    let _taskIdentifier: Int
    override var taskIdentifier: Int {
        return _taskIdentifier
    }

    override var originalRequest: NSURLRequest? {
        return request
    }

    override var currentRequest: NSURLRequest? {
        return request
    }

    var _response: NSURLResponse? = nil
    override var response: NSURLResponse? {
        return _response
    }

    var _state: NSURLSessionTaskState = .Suspended
    override var state: NSURLSessionTaskState {
        return _state
    }

    // MARK: - Initializers

    init(taskIdentifier: Int, session: Session, request: NSURLRequest, completion: Completion? = nil) {
        self.session = session
        self.request = request
        self.completion = completion
        _taskIdentifier = taskIdentifier
    }

    // MARK: - NSURLSessionTask

    override func cancel() {
        // Don't do anything
    }

    override func resume() {
        var task: SessionDataTask! = nil
        task = SessionDataTask(taskIdentifier: taskIdentifier, session: session, request: request) { data, response, error in
            let location: NSURL?
            if let data = data {
                // Write data to temporary file
                let tempURL = NSURL(fileURLWithPath: (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(NSUUID().UUIDString))
                data.writeToURL(tempURL, atomically: true)
                location = tempURL

                // Notify the delegate
                if let delegate = task.session.delegate as? NSURLSessionDownloadDelegate {
                    delegate.URLSession(task.session, downloadTask: self, didFinishDownloadingToURL: tempURL)
                }
            } else {
                location = nil
            }

            self.completion?(location, response, error)
            task._state = .Running
        }
        task.resume()
        task._state = .Running
    }
}
