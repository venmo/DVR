import Foundation

class SessionDataTask: NSURLSessionDataTask {

    // MARK: - Types

    typealias Completion = (NSData?, NSURLResponse?, NSError?) -> Void


    // MARK: - Properties

    weak var session: Session!
    let request: NSURLRequest
    let completion: Completion?
    private let queue = dispatch_queue_create("com.venmo.DVR.sessionDataTaskQueue", nil)

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

    init(taskIdentifier: Int, session: Session, request: NSURLRequest, completion: (Completion)? = nil) {
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
        _state = .Running
        
        let cassette = session.cassette

        // Find interaction
        if let interaction = session.cassette?.interactionForRequest(request) {

            _response = interaction.response

            if let delegate = session.delegate as? NSURLSessionDataDelegate {

                // Delegate message #1
                delegate.URLSession?(session, dataTask: self, didReceiveResponse: interaction.response, completionHandler: { (disposition) -> Void in
                    // TODO
                })

                // Delegate message #2
                if let responseData = interaction.responseData {
                    delegate.URLSession?(session, dataTask: self, didReceiveData: responseData)
                }

                // Delegate message #3
                delegate.URLSession?(session, task: self, didCompleteWithError: nil)
            }

            // Forward completion
            if let completion = completion {
                dispatch_async(queue) {
                    completion(interaction.responseData, interaction.response, nil)
                }
            }

            _state = .Completed
            session.finishTask(self, interaction: interaction, playback: true)
            return
        }

        if cassette != nil {
            print("[DVR] Invalid request. The request was not found in the cassette.")
            abort()
        }

        // Cassette is missing. Record.
        if session.recordingEnabled == false {
            print("[DVR] Recording is disabled.")
            abort()
        }

        let task = session.backingSession.dataTaskWithRequest(request) { [weak self] data, response, error in

            //Ensure we have a response
            guard let response = response else {
                print("[DVR] Failed to record because the task returned a nil response.")
                abort()
            }

            guard let this = self else {
                print("[DVR] Something has gone horribly wrong.")
                abort()
            }

            // Still call the completion block so the user can chain requests while recording.
            dispatch_async(this.queue) {
                this.completion?(data, response, nil)
                self?._state = .Completed
            }

            // Create interaction
            let interaction = Interaction(request: this.request, response: response, responseData: data)
            this.session.finishTask(this, interaction: interaction, playback: false)
        }
        task.resume()
    }
}
