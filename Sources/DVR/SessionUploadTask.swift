import Foundation

final class SessionUploadTask: URLSessionUploadTask {

    // MARK: - Types

    typealias Completion = (Data?, Foundation.URLResponse?, NSError?) -> Void

    // MARK: - Properties

    weak var session: Session!
    let request: URLRequest
    let headersToCheck: [String]
    let completion: Completion?
    let dataTask: SessionDataTask

    // MARK: - Initializers

    init(session: Session, request: URLRequest, headersToCheck: [String] = [], completion: Completion? = nil) {
        self.session = session
        self.request = request
        self.headersToCheck = headersToCheck
        self.completion = completion
        dataTask = SessionDataTask(session: session, request: request, headersToCheck: headersToCheck, completion: completion)
    }

    // MARK: - URLSessionTask

    override func cancel() {
        // Don't do anything
    }

    override func resume() {
        dataTask.resume()
    }
}
