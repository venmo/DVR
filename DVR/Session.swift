import Foundation

public class Session: NSURLSession {

    // MARK: - Properties

    public let cassetteName: String


    // MARK: - Initializers

    public init(cassetteName: String) {
        self.cassetteName = cassetteName
        super.init()
    }


    // MARK: - NSURLSession

    public override func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask? {
        return SessionDataTask(cassetteName: cassetteName, request: request, completion: completionHandler)
    }
}
