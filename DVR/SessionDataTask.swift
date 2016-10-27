import Foundation

class SessionDataTask: NSURLSessionDataTask {

    // MARK: - Types

    typealias Completion = (NSData?, NSURLResponse?, NSError?) -> Void


    // MARK: - Properties

    weak var session: Session!
    let request: NSURLRequest
    let completion: Completion?
    private let queue = dispatch_queue_create("com.venmo.DVR.sessionDataTaskQueue", nil)
    private var interaction: Interaction?

    override var response: NSURLResponse? {
        return interaction?.response
    }


    // MARK: - Initializers

    init(session: Session, request: NSURLRequest, completion: (Completion)? = nil) {
        self.session = session
        self.request = request
        self.completion = completion
    }


    // MARK: - NSURLSessionTask

    override func cancel() {
        // Don't do anything
    }

    override func resume() {
        let cassette = session.cassette

        // Find interaction
        if let interaction = session.cassette?.interactionForRequest(request) {
            self.interaction = interaction
            // Forward completion
            if let completion = completion {
                dispatch_async(queue) {
                    completion(interaction.responseData, interaction.response, nil)
                }
            }
            session.finishTask(self, interaction: interaction, playback: true)
            return
        }

        if cassette != nil {
            fatalError("[DVR] Invalid request. The request was not found in the cassette.")
        }

        // Cassette is missing. Record.
        if session.recordingEnabled == false {
            fatalError("[DVR] Recording is disabled.")
        }

        let task = session.backingSession.dataTaskWithRequest(request) { [weak self] data, response, error in

            //Ensure we have a response
            guard let response = response else {
                fatalError("[DVR] Failed to record because the task returned a nil response.")
            }

            guard let this = self else {
                fatalError("[DVR] Something has gone horribly wrong.")
            }

            // Still call the completion block so the user can chain requests while recording.
            dispatch_async(this.queue) {
                this.completion?(data, response, nil)
            }

            // Create interaction
            this.interaction = Interaction(request: this.request, response: response, responseData: data)
            this.session.finishTask(this, interaction: this.interaction!, playback: false)
        }
        task.resume()
    }
}
