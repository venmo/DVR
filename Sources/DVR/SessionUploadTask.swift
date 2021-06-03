import Foundation

final class SessionUploadTask: URLSessionUploadTask {

    // MARK: - Types

    typealias Completion = (Data?, Foundation.URLResponse?, NSError?) -> Void

    // MARK: - Properties

    weak var session: Session!
    let request: URLRequest
    let requiredHeaders: [String]
    let completion: Completion?
    let dataTask: SessionDataTask

    // MARK: - Initializers

    init(session: Session, request: URLRequest, requiredHeaders: [String] = [], completion: Completion? = nil) {
        self.session = session
        self.request = request
        self.requiredHeaders = requiredHeaders
        self.completion = completion
        dataTask = SessionDataTask(session: session, request: request, requiredHeaders: requiredHeaders, completion: completion)
    }

    // MARK: - URLSessionTask

    override func cancel() {
        // Don't do anything
    }

    override func resume() {
        dataTask.resume()
    }
}
