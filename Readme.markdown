# DVR

[![Version](https://img.shields.io/github/release/venmo/DVR.svg)](https://github.com/venmo/DVR/releases) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

DVR is a simple Swift framework for making fake `NSURLSession` requests for iOS,
watchOS, and OS X based on [VCR](https://github.com/vcr/vcr).

Easy [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection) is the main design goal. The API is the same as `NSURLSession`. `DVR.Session` is a subclass of `NSURLSession` so you can use it as a drop in replacement anywhere. (Currently only data tasks are supported.)


## Version Compatibility

| Swift Version | DVR Version |
| ------------- | ----------- |
| 3.2+          | 1.1         |
| 3.0           | 1.0         |
| 2.3           | 0.4         |
| 2.2           | 0.3         |
| < 2.2         | 0.2.1       |


## Usage

```swift
let session = Session(cassetteName: "example")
let task = session.dataTaskWithRequest(request) { data, response, error in
    // Do something with the response
}

// Nothing happens until you call `resume` as you'd expect.
task.resume()
```

This will playback the `example` cassette. The completion handler exactly the same way it normally would. In this example, DVR will look for a cassette named `example.json` in your test bundle.

If the recording of the request is missing, it will record and save it to disk. After saving to disk, it will assert with path of the recorded file. This causes the tests to stop so you can add the cassette to your test target and rerun your tests.


### Recording Multiple Requests

By default, a DVR session only records one request. You can record multiple requests in the same cassette if you tell DVR when to start and stop recording.

``` swift
let session = Session(cassetteName: "multiple")

// Begin recording multiple requests
session.beginRecording()

session.dataTaskWithRequest(NSURLRequest(URL: NSURL(string: "http://apple.com")!)) { data, response, error in
    // Do something with the response

    session.dataTaskWithRequest(NSURLRequest(URL: NSURL(string: "http://google.com")!)) { data, response, error in
        // Do something with the response
    }.resume()

    // Finish recording multiple requests
    session.endRecording() {
        // All requests have completed
    }
}.resume()
```

If you don't call `beginRecording` and `endRecording`, DVR will call these for your around the first request you make to a session. You can call `endRecording` immediately after you've submitted all of your requests to the session. The optional completion block that `endRecording` accepts will be called when all requests have finished. This is a good spot to fulfill XCTest expectations you've setup or do whatever else now that networking has finished.
