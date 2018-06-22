import Foundation

private var globalTaskIdentifier: Int = 300000

final class SessionUploadTask: URLSessionUploadTask {

    // MARK: - Types

    typealias Completion = (Data?, Foundation.URLResponse?, NSError?) -> Void

    // MARK: - Properties

    weak var session: Session!
    let request: URLRequest
    let completion: Completion?
    let dataTask: SessionDataTask

    var _taskIdentifier: Int = {
      globalTaskIdentifier += 1
      return globalTaskIdentifier
    }()
    override var taskIdentifier: Int {
      return _taskIdentifier
    }

    var _originalRequest: URLRequest?
    override var originalRequest: URLRequest? {
      return _originalRequest
    }

    // MARK: - Initializers

    init(session: Session, request: URLRequest, completion: Completion? = nil) {
        self.session = session
        self.request = request
        self.completion = completion
        dataTask = SessionDataTask(session: session, request: request, completion: completion)
    }

    // MARK: - URLSessionTask

    override func cancel() {
        // Don't do anything
    }

    override func resume() {
        dataTask.resume()
    }
}
