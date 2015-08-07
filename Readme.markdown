# DVR

[![Version](https://img.shields.io/github/release/venmo/DVR.svg)](https://github.com/venmo/DVR/releases) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

DVR is a simple Swift framework for making fake `NSURLSession` requests based on [VCR](https://github.com/vcr/vcr) for iOS, watchOS, and OS X.

Easy [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection) is the main design goal. The API is the same as `NSURLSession`. `DVR.Session` is a subclass of `NSURLSession` so you can use it as a drop in replacement anywhere. (Currently only data tasks are supported.)


## Building

Xcode 7 beta 5 is required since DVR is written in Swift 2.


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
