import Foundation

final class SessionDownloadTask: URLSessionDownloadTask {

    // MARK: - Types

    typealias Completion = (URL?, Foundation.URLResponse?, NSError?) -> Void

    // MARK: - Properties

    weak var session: Session!
    let request: URLRequest
    let headersToCheck: [String]
    let completion: Completion?


    // MARK: - Initializers

    init(session: Session, request: URLRequest, headersToCheck: [String] = [], completion: Completion? = nil) {
        self.session = session
        self.request = request
        self.headersToCheck = headersToCheck
        self.completion = completion
    }

    // MARK: - URLSessionTask

    override func cancel() {
        // Don't do anything
    }

    override func resume() {
        let task = SessionDataTask(session: session, request: request, headersToCheck: headersToCheck) { data, response, error in
            let location: URL?
            if let data = data {
                // Write data to temporary file
                let tempURL = URL(fileURLWithPath: (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString))
                try? data.write(to: tempURL, options: [.atomic])
                location = tempURL
            } else {
                location = nil
            }

            self.completion?(location, response, error)
        }
        task.resume()
    }
}
