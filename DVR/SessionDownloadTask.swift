public class SessionDownloadTask: URLSessionDownloadTask {

    // MARK: - Properties

    weak var session: Session!
    let request: URLRequest
    let completion: (URL?, Foundation.URLResponse?, Error?) -> Void


    // MARK: - Initializers

    init(session: Session, request: URLRequest, completion: @escaping (URL?, Foundation.URLResponse?, Error?) -> Void) {
        self.session = session
        self.request = request
        self.completion = completion
    }

    // MARK: - NSURLSessionTask

    override public func cancel() {
        // Don't do anything
    }

    override public func resume() {
        let task = SessionDataTask(session: session, request: request) { data, response, error in
            let location: URL?
            if let data = data {
                // Write data to temporary file
                let tempURL = URL(fileURLWithPath: (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString))
                try? data.write(to: tempURL, options: [.atomic])
                location = tempURL
            } else {
                location = nil
            }

            self.completion(location, response, error)
        }
        task.resume()
    }
}
