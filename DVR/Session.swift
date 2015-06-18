import Foundation

public class Session: NSURLSession {

    // MARK: - Properties

    public let cassettesDirectory: String
    public let cassetteName: String


    // MARK: - Initializers

    public init(cassettesDirectory: String = "Cassettes", cassetteName: String) {
        self.cassettesDirectory = cassettesDirectory
        self.cassetteName = cassetteName
        super.init()
    }


    // MARK: - NSURLSession

    public override func dataTaskWithRequest(request: NSURLRequest) -> NSURLSessionDataTask? {
        return SessionDataTask(cassettesDirectory: cassettesDirectory, cassetteName: cassetteName, request: request)
    }

    public override func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask? {
        return SessionDataTask(cassettesDirectory: cassettesDirectory, cassetteName: cassetteName, request: request, completion: completionHandler)
    }
}
