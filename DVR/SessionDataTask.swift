import Foundation

class SessionDataTask: NSURLSessionDataTask {
    let cassetteName: String
    let request: NSURLRequest
    let completion: (NSData?, NSURLResponse?, NSError?) -> Void

    init(cassetteName: String, request: NSURLRequest, completion: (NSData?, NSURLResponse?, NSError?) -> Void) {
        self.cassetteName = cassetteName
        self.request = request
        self.completion = completion
    }

    override func resume() {
        // TODO: Get the stubbed request from disk
        // TODO: Call the completion handler with fake data
    }
}
