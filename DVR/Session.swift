import Foundation

public class Session: NSURLSession {

    // MARK: - Properties

    public var outputDirectory: String
    public let cassetteName: String
    public let backingSession: NSURLSession
    public var recordingEnabled = true

    private let testBundle: NSBundle

    private var recording = false
    private var needsPersistence = false
    private var outstandingTasks = [NSURLSessionTask]()
    private var completedInteractions = [Interaction]()
    private var completionBlock: (Void -> Void)?

    private static var nextTaskID: Int = 0
    private let idGenerationQueue = dispatch_queue_create("com.venmo.DVR.idGenerationQueue", nil)

    private let _delegate: NSURLSessionDelegate?
    override public var delegate: NSURLSessionDelegate? {
        return _delegate
    }

    // MARK: - Initializers

    public init(outputDirectory: String = "~/Desktop/DVR/", cassetteName: String, testBundle: NSBundle = NSBundle.allBundles().filter() { $0.bundlePath.hasSuffix(".xctest") }.first!, backingSession: NSURLSession = NSURLSession.sharedSession(), delegate: NSURLSessionDelegate? = nil) {
        self.outputDirectory = outputDirectory
        self.cassetteName = cassetteName
        self.testBundle = testBundle
        self.backingSession = backingSession
        _delegate = delegate
        super.init()
    }


    // MARK: - NSURLSession

    public override func dataTaskWithRequest(request: NSURLRequest) -> NSURLSessionDataTask {
        return addDataTask(request)
    }

    public override func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
        return addDataTask(request, completionHandler: completionHandler)
    }

    public override func downloadTaskWithRequest(request: NSURLRequest) -> NSURLSessionDownloadTask {
        return addDownloadTask(request)
    }

    public override func downloadTaskWithRequest(request: NSURLRequest, completionHandler: (NSURL?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDownloadTask {
        return addDownloadTask(request, completionHandler: completionHandler)
    }

    public override func invalidateAndCancel() {
        recording = false
        outstandingTasks.removeAll()
        backingSession.invalidateAndCancel()
    }


    // MARK: - Recording

    /// You don’t need to call this method if you're only recoding one request.
    public func beginRecording() {
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
    public func endRecording(completion: (Void -> Void)? = nil) {
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
        guard let path = testBundle.pathForResource(cassetteName, ofType: "json"),
            data = NSData(contentsOfFile: path),
            raw = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
            json = raw as? [String: AnyObject]
        else { return nil }

        return Cassette(dictionary: json)
    }

    func finishTask(task: NSURLSessionTask, interaction: Interaction, playback: Bool) {
        needsPersistence = needsPersistence || !playback

        if let index = outstandingTasks.indexOf(task) {
            outstandingTasks.removeAtIndex(index)
        }

        completedInteractions.append(interaction)

        if !recording && outstandingTasks.count == 0 {
            finishRecording()
        }
    }


    // MARK: - Private

    private func generateNextTaskID() -> Int {
        var id: Int!
        dispatch_sync(idGenerationQueue) {
            id = Session.nextTaskID
            Session.nextTaskID += 1
        }
        return id
    }

    private func addDataTask(request: NSURLRequest, completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)? = nil) -> NSURLSessionDataTask {
        let modifiedRequest = backingSession.configuration.HTTPAdditionalHeaders.map(request.requestByAppendingHeaders) ?? request
        let task = SessionDataTask(taskIdentifier: generateNextTaskID(), session: self, request: modifiedRequest, completion: completionHandler)
        addTask(task)
        return task
    }

    private func addDownloadTask(request: NSURLRequest, completionHandler: SessionDownloadTask.Completion? = nil) -> NSURLSessionDownloadTask {
        let modifiedRequest = backingSession.configuration.HTTPAdditionalHeaders.map(request.requestByAppendingHeaders) ?? request
        let task = SessionDownloadTask(taskIdentifier: generateNextTaskID(), session: self, request: modifiedRequest, completion: completionHandler)
        addTask(task)
        return task
    }

    private func addTask(task: NSURLSessionTask) {
        let shouldRecord = !recording
        if shouldRecord {
            beginRecording()
        }

        outstandingTasks.append(task)

        if shouldRecord {
            endRecording()
        }
    }

    private func persist(interactions: [Interaction]) {
        defer {
            abort()
        }

        // Create directory
        let outputDirectory = (self.outputDirectory as NSString).stringByExpandingTildeInPath
        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(outputDirectory) {
			do {
				try fileManager.createDirectoryAtPath(outputDirectory, withIntermediateDirectories: true, attributes: nil)
			} catch {
				print("[DVR] Failed to create cassettes directory.")
			}
        }

        let cassette = Cassette(name: cassetteName, interactions: interactions)

        // Persist


        do {
            let outputPath = ((outputDirectory as NSString).stringByAppendingPathComponent(cassetteName) as NSString).stringByAppendingPathExtension("json")!
            let data = try NSJSONSerialization.dataWithJSONObject(cassette.dictionary, options: [.PrettyPrinted])

            // Add trailing new line
            guard var string = NSString(data: data, encoding: NSUTF8StringEncoding) else {
                print("[DVR] Failed to persist cassette.")
                return
            }
            string = string.stringByAppendingString("\n")

            if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
                data.writeToFile(outputPath, atomically: true)
                print("[DVR] Persisted cassette at \(outputPath). Please add this file to your test target")
            }

            print("[DVR] Failed to persist cassette.")
        } catch {
            print("[DVR] Failed to persist cassette.")
        }
    }

    private func finishRecording() {
        if needsPersistence {
            persist(completedInteractions)
        }

        // Clean up
        completedInteractions = []

        // Call session’s completion block
        completionBlock?()
    }
}
