import Foundation

open class Session: URLSession {

    // MARK: - Properties

    open var outputDirectory: String
    open let cassetteName: String
    open let backingSession: URLSession
    open var recordingEnabled = true

    fileprivate let testBundle: Bundle

    fileprivate var recording = false
    fileprivate var needsPersistence = false
    fileprivate var outstandingTasks = [URLSessionTask]()
    fileprivate var completedInteractions = [Interaction]()
    fileprivate var completionBlock: ((Void) -> Void)?


    // MARK: - Initializers

    public init(outputDirectory: String = "~/Desktop/DVR/", cassetteName: String, testBundle: Bundle = Bundle.allBundles.filter() { $0.bundlePath.hasSuffix(".xctest") }.first!, backingSession: URLSession = URLSession.shared) {
        self.outputDirectory = outputDirectory
        self.cassetteName = cassetteName
        self.testBundle = testBundle
        self.backingSession = backingSession
        super.init()
    }


    // MARK: - NSURLSession

    open override func dataTask(with request: URLRequest) -> URLSessionDataTask {
        return addDataTask(request)
    }

    open override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return addDataTask(request, completionHandler: completionHandler)
    }

    open override func downloadTask(with request: URLRequest) -> URLSessionDownloadTask {
        return addDownloadTask(request)
    }

    open override func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        return addDownloadTask(request, completionHandler: completionHandler)
    }

    open override func invalidateAndCancel() {
        recording = false
        outstandingTasks.removeAll()
        backingSession.invalidateAndCancel()
    }


    // MARK: - Recording

    /// You don’t need to call this method if you're only recoding one request.
    open func beginRecording() {
        if recording {
            return
        }

        recording = true
        needsPersistence = false
        outstandingTasks = []
        completedInteractions = []
        completionBlock = nil
    }

    /// This only needs to be called if you call `beginRecording`. `completion` will be called on the main queue after
    /// the completion block of the last task is called. `completion` is useful for fulfilling an expectation you setup
    /// before calling `beginRecording`.
    open func endRecording(_ completion: ((Void) -> Void)? = nil) {
        if !recording {
            return
        }

        recording = false
        completionBlock = completion

        if outstandingTasks.count == 0 {
            finishRecording()
        }
    }


    // MARK: - Internal

    var cassette: Cassette? {
        guard let path = testBundle.path(forResource: cassetteName, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let raw = try? JSONSerialization.jsonObject(with: data, options: []),
            let json = raw as? [String: Any]
        else {
            return nil
        }

        let cassette = Cassette(dictionary: json)

        if cassette == nil || cassette!.interactions.isEmpty {
            print("blah")
        }

        return cassette
    }

    func finishTask(_ task: URLSessionTask, interaction: Interaction, playback: Bool) {
        needsPersistence = needsPersistence || !playback

        if let index = outstandingTasks.index(of: task) {
            outstandingTasks.remove(at: index)
        }

        completedInteractions.append(interaction)

        if !recording && outstandingTasks.count == 0 {
            finishRecording()
        }
    }


    // MARK: - Private

    fileprivate func addDataTask(_ request: URLRequest, completionHandler: ((Data?, Foundation.URLResponse?, NSError?) -> Void)? = nil) -> URLSessionDataTask {
        let modifiedRequest = backingSession.configuration.httpAdditionalHeaders.map(request.requestByAppendingHeaders) ?? request
        let task = SessionDataTask(session: self, request: modifiedRequest, completion: completionHandler)
        addTask(task)
        return task
    }

    fileprivate func addDownloadTask(_ request: URLRequest, completionHandler: SessionDownloadTask.Completion? = nil) -> URLSessionDownloadTask {
        let modifiedRequest = backingSession.configuration.httpAdditionalHeaders.map(request.requestByAppendingHeaders) ?? request
        let task = SessionDownloadTask(session: self, request: modifiedRequest, completion: completionHandler)
        addTask(task)
        return task
    }

    fileprivate func addTask(_ task: URLSessionTask) {
        let shouldRecord = !recording
        if shouldRecord {
            beginRecording()
        }

        outstandingTasks.append(task)

        if shouldRecord {
            endRecording()
        }
    }

    fileprivate func persist(_ interactions: [Interaction]) {
        defer {
            abort()
        }

        // Create directory
        let outputDirectory = (self.outputDirectory as NSString).expandingTildeInPath
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: outputDirectory) {
			do {
				try fileManager.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true, attributes: nil)
			} catch {
				print("[DVR] Failed to create cassettes directory.")
			}
        }

        let cassette = Cassette(name: cassetteName, interactions: interactions)

        // Persist


        do {
            let outputPath = ((outputDirectory as NSString).appendingPathComponent(cassetteName) as NSString).appendingPathExtension("json")!
            let data = try JSONSerialization.data(withJSONObject: cassette.dictionary, options: [.prettyPrinted])

            // Add trailing new line
            guard var string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
                print("[DVR] Failed to persist cassette.")
                return
            }
            string = string.appending("\n") as NSString

            if let data = string.data(using: String.Encoding.utf8.rawValue) {
                try? data.write(to: URL(fileURLWithPath: outputPath), options: [.atomic])
                print("[DVR] Persisted cassette at \(outputPath). Please add this file to your test target")
            }

            print("[DVR] Failed to persist cassette.")
        } catch {
            print("[DVR] Failed to persist cassette.")
        }
    }

    fileprivate func finishRecording() {
        if needsPersistence {
            persist(completedInteractions)
        }

        // Clean up
        completedInteractions = []

        // Call session’s completion block
        completionBlock?()
    }
}
