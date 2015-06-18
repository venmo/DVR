# DVR

DVR is a simple Swift framework for making fake `NSURLSession` requests based on [VCR](https://github.com/vcr/vcr).

Easy [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection) is the main design goal. The API is the same as `NSURLSession`. `DVR.Session` is a subclass of `NSURLSession` so you can use it as a drop in replacement anywhere. (Currently only data tasks are supported.)


## Usage

```swift
let session = Session(cassettesName: "example")
let task = session.dataTaskWithRequest(request) { data, response, error in
  // Do something with the response
}

// Nothing happens until you call `resume` as you'd expect.
task.resume()
```

This will call the completion handler exactly the same way it normally would. If the recording of the request is missing, it will record and save it to disk. For subsuquent requests, it will playback the response for that request.
