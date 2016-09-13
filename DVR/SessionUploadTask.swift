public class SessionUploadTask: URLSessionUploadTask {

    // MARK: - Properties

    weak var session: Session!
    let request: URLRequest
    let completion: (Data?, Foundation.URLResponse?, Error?) -> Void
    let dataTask: SessionDataTask

    // MARK: - Initializers

    init(session: Session, request: URLRequest, completion: @escaping (Data?, Foundation.URLResponse?, Error?) -> Void) {
        self.session = session
        self.request = request
        self.completion = completion
        dataTask = SessionDataTask(session: session, request: request, completion: completion)
    }

    // MARK: - NSURLSessionTask

    override public func cancel() {
        // Don't do anything
    }

    override public func resume() {
        dataTask.resume()
    }
}
