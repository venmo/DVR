import Foundation

final class SessionDataTask: URLSessionDataTask {

    // MARK: - Types

    typealias Completion = (Data?, Foundation.URLResponse?, NSError?) -> Void


    // MARK: - Properties

    weak var session: Session!
    let request: URLRequest
    let completion: Completion?
    fileprivate let queue = DispatchQueue(label: "com.venmo.DVR.sessionDataTaskQueue", attributes: [])
    fileprivate var interaction: Interaction?

    override var response: Foundation.URLResponse? {
        return interaction?.response
    }


    // MARK: - Initializers

    init(session: Session, request: URLRequest, completion: (Completion)? = nil) {
        self.session = session
        self.request = request
        self.completion = completion
    }


    // MARK: - URLSessionTask

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
                queue.async {
                    completion(interaction.responseData, interaction.response, nil)
                }
            }
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

        let task = session.backingSession.dataTask(with: request, completionHandler: { [weak self] data, response, error in

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
            this.queue.async {
                this.completion?(data, response, nil)
            }

            // Create interaction
            this.interaction = Interaction(request: this.request, response: response, responseData: data)
            this.session.finishTask(this, interaction: this.interaction!, playback: false)
        }) 
        task.resume()
    }
}
