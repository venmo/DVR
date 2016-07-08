import Foundation

struct Cassette {

    // MARK: - Properties

    let name: String
    let interactions: [Interaction]
    let cassetteOptions: CassetteOptions

    // MARK: - Initializers

    init(name: String, interactions: [Interaction], cassetteOptions: CassetteOptions) {
        self.name = name
        self.interactions = interactions
        self.cassetteOptions = cassetteOptions
    }

    // MARK: - Functions

    func interactionForRequest(request: NSURLRequest) -> Interaction? {
        for interaction in interactions {
            let interactionRequest = interaction.request
            
            if cassetteOptions.requestMatching == [.URL, .Path, .HTTPMethod, .HTTPBody] {
                guard
                    interactionRequest.URL == request.URL &&
                    interactionRequest.URL?.relativePath == request.URL?.relativePath &&
                    interactionRequest.HTTPMethod == request.HTTPMethod &&
                    interactionRequest.hasHTTPBodyEqualToThatOfRequest(request)
                else {
                    continue
                }
                
                return interaction
            }
            
            if cassetteOptions.requestMatching == [.URL, .Path] {
                guard
                    interactionRequest.URL == request.URL &&
                    interactionRequest.URL?.relativePath == request.URL?.relativePath
                else {
                    continue
                }
                
                return interaction
            }
            
            if cassetteOptions.requestMatching == [.URL, .HTTPMethod] {
                guard
                    interactionRequest.URL == request.URL &&
                    interactionRequest.HTTPMethod == request.HTTPMethod
                else {
                    continue
                }
                
                return interaction
            }
           
            if cassetteOptions.requestMatching == [.URL, .HTTPBody] {
                guard
                    interactionRequest.URL == request.URL &&
                    interactionRequest.hasHTTPBodyEqualToThatOfRequest(request)
                else {
                    continue
                }
                
                return interaction
            }
            
            if cassetteOptions.requestMatching == [.Path, .HTTPMethod] {
                guard
                    interactionRequest.URL?.relativePath == request.URL?.relativePath &&
                        interactionRequest.HTTPMethod == request.HTTPMethod
                else {
                    continue
                }
                
                return interaction
            }
            
            if cassetteOptions.requestMatching == [.Path, .HTTPBody] {
                guard
                    interactionRequest.URL?.relativePath == request.URL?.relativePath &&
                    interactionRequest.hasHTTPBodyEqualToThatOfRequest(request)
                else {
                        continue
                }
                
                return interaction
            }

            if cassetteOptions.requestMatching == [.HTTPMethod, .HTTPBody] {
                guard
                    interactionRequest.HTTPMethod == request.HTTPMethod &&
                    interactionRequest.hasHTTPBodyEqualToThatOfRequest(request)
                else {
                    continue
                }
                
                return interaction
            }
            
            if cassetteOptions.requestMatching == [.URL] {
                guard
                    interactionRequest.URL == request.URL
                else {
                    continue
                }
                
                return interaction
            }
            
            if cassetteOptions.requestMatching == [.Path] {
                guard
                    interactionRequest.URL?.relativePath == request.URL?.relativePath
                else {
                    continue
                }
                
                return interaction
            }
            
            if cassetteOptions.requestMatching == [.HTTPMethod] {
                guard
                    interactionRequest.HTTPMethod == request.HTTPMethod
                else {
                    continue
                }
                
                return interaction
            }
            
            if cassetteOptions.requestMatching == [.HTTPBody] {
                guard
                    interactionRequest.hasHTTPBodyEqualToThatOfRequest(request)
                else {
                    continue
                }
                
                return interaction
            }
        }
        
        return nil
    }
}

extension Cassette {
    var dictionary: [String: AnyObject] {
        return [
            "name": name,
            "interactions": interactions.map { $0.dictionary }
        ]
    }

    init?(dictionary: [String: AnyObject], cassetteOptions: CassetteOptions) {
        guard let name = dictionary["name"] as? String else { return nil }

        self.name = name
        self.cassetteOptions = cassetteOptions

        if let array = dictionary["interactions"] as? [[String: AnyObject]] {
            interactions = array.flatMap { Interaction(dictionary: $0) }
        } else {
            interactions = []
        }
    }
}

private extension NSURLRequest {
    func hasHTTPBodyEqualToThatOfRequest(request: NSURLRequest) -> Bool {
        guard let body1 = self.HTTPBody,
            body2 = request.HTTPBody,
            encoded1 = Interaction.encodeBody(body1, headers: self.allHTTPHeaderFields),
            encoded2 = Interaction.encodeBody(body2, headers: request.allHTTPHeaderFields)
        else {
            return self.HTTPBody == request.HTTPBody
        }

        return encoded1.isEqual(encoded2)
    }
}
