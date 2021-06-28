import Foundation


final class SessionDataTask: URLSessionDataTask {

    // MARK: - Types

    typealias Completion = (Data?, Foundation.URLResponse?, NSError?) -> Void

    

    // MARK: - Properties

    var session: Session!
    let request: URLRequest
    let headersToCheck: [String]
    let completion: Completion?
    private let queue = DispatchQueue(label: "com.venmo.DVR.sessionDataTaskQueue", attributes: [])
    private var interaction: Interaction?

    override var response: Foundation.URLResponse? {
        return interaction?.response
    }

    override var currentRequest: URLRequest? {
        return request
    }

    // MARK: - Initializers

    init(session: Session, request: URLRequest, headersToCheck: [String] = [], completion: (Completion)? = nil) {
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

        // apply request transformations, which could impact matching the interaction
        let filteredRequest = filter(request: request)

        if session.recordMode != .all {
            let cassette = session.cassette

            // Find interaction
            if let interaction = session.cassette?.interactionForRequest(filteredRequest, headersToCheck: headersToCheck) {
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

            // Errors unless playbackMode = .newEpisodes
            if cassette != nil && session.recordMode != .newEpisodes {
                
                fatalError("[DVR] Invalid request. The request was not found in the cassette.")
            }

            // Errors if in playbackMode = .none
            if cassette == nil && session.recordMode == .none {
                fatalError("[DVR] No Recording Found.")
            }
            
            // Cassette is missing. Record.
            if session.recordingEnabled == false {
                fatalError("[DVR] Recording is disabled.")
            }
        }

        let task = session.backingSession.dataTask(with: request, completionHandler: { [weak self] data, response, error in

            //Ensure we have a response
            guard let response = response else {
                fatalError("[DVR] Failed to record because the task returned a nil response.")
            }

            guard let this = self else {
                fatalError("[DVR] Something has gone horribly wrong.")
            }

            // Still call the completion block so the user can chain requests while recording.
            this.queue.async {
                this.completion?(data, response, nil)
            }
            
            // Create interaction unless the response has been filtered out
            if let (filteredResponse, filteredData) = this.filter(response: response, withData: data) {
                // persist the interaction
                this.interaction = Interaction(request: filteredRequest, response: filteredResponse, responseData: filteredData)
                this.session.finishTask(this, interaction: this.interaction!, playback: false)
            } else {
                // do not persist the interaction if the filtered response was nil
                this.interaction = Interaction(request: filteredRequest, response: response, responseData: data)
                this.session.finishTask(this, interaction: this.interaction!, playback: true)
            }
        })
        task.resume()
    }

    // MARK: - Internal Methods

    func filterHeaders(for request: inout URLRequest) {
        // return early if request has no headers
        guard var filteredHeaders = request.allHTTPHeaderFields else {
            return
        }
        for (key, filter) in session.filter.filterHeaders ?? [:] {
            guard let match = filteredHeaders[key] else {
                continue
            }
            switch filter {
            case .remove:
                filteredHeaders[key] = nil
            case let .replace(replacement):
                filteredHeaders[key] = replacement
            case let .closure(function):
                filteredHeaders[key] = function(key, match)
            }
        }
        request.allHTTPHeaderFields = filteredHeaders
    }

    func filterQueryParams(for request: inout URLRequest) {
        // return early if request has no query params
        guard let url = request.url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        var filteredQueryParams: [URLQueryItem] = []
        for item in queryItems {
            guard let filterMatch = session.filter.filterQueryParameters?[item.name] else {
                continue
            }
            switch filterMatch {
            case .remove:
                continue
            case let .replace(replacement):
                filteredQueryParams.append(URLQueryItem(name: item.name, value: replacement))
            case let .closure(function):
                // don't add if the closure returns nil
                if let newValue = function(item.name, item.value) {
                    filteredQueryParams.append(URLQueryItem(name: item.name, value: newValue))
                }
            }
        }
        components.queryItems = filteredQueryParams
        request.url = components.url
    }

    func filterPostParams(for request: inout URLRequest) {
        // return early if request is not a POST or has no body params
        guard request.httpMethod == "POST",
              let httpBody = request.httpBody,
              var jsonBody = try? JSONSerialization.jsonObject(with: httpBody, options: [.mutableContainers]) else {
            return
        }
        // TODO: needs to account for different ways of encoding form data
    }

    func filter(request: URLRequest) -> URLRequest {
        var filtered = request
        filterHeaders(for: &filtered)
        filterQueryParams(for: &filtered)
        filterPostParams(for: &filtered)
        filtered = session.filter.beforeRecordRequest?(filtered) ?? filtered
        return filtered
    }

    func filter(response: Foundation.URLResponse, withData data: Data?) -> (Foundation.URLResponse, Data?)? {
        //  return the same data if no filter present
        guard let responseFilter = session.filter.beforeRecordResponse else {
            return (response, data)
        }
        return responseFilter(response, data)
    }
}

