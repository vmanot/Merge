//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Foundation
@_spi(Internal) import Swallow
import System

public enum _AsyncProcessOption: Hashable {
    case reportCompletion
    case splitWithNewLine
    case trimming(CharacterSet)
    
    case _useAppleScript
    case _useAuthorizationExecuteWithPrivileges
}

#if os(macOS) || targetEnvironment(macCatalyst)

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension _AsyncProcess {
    @MutexProtected
    public static var runningProcesses = [_AsyncProcess]()
}

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
public class _AsyncProcess: Logging {
    public typealias Option = _AsyncProcessOption
    public typealias ProgressHandler = Shell.ProgressHandler
    
    struct _Publishers {
        let standardOutputPublisher = ReplaySubject<Data, Never>()
        let standardErrorPublisher = ReplaySubject<Data, Never>()
        let exitPublisher = ReplaySubject<Int32, Never>()
    }
    
    public let progressHandler: _AsyncProcess.ProgressHandler
    public let options: [Option]
    public let process: Process
    
    private let _publishers = _Publishers()
    private let processDidStart = _AsyncGate(initiallyOpen: false)
    private let processDidExit = _AsyncGate(initiallyOpen: false)
    
    @_OSUnfairLocked
    private var isWaiting = false
    private var _standardInputPipe: Pipe?
    private var _standardOutputPipe: Pipe?
    private var _standardErrorPipe: Pipe?
    
    private var standardOutputCache = ""
    
    @_OSUnfairLocked
    private var _result: Result<_ProcessResult, Error>?
    
    public private(set) var _standardOutputString = ""
    public private(set) var _standardErrorString = ""
    
    var standardInputPipe: Pipe? {
        if state == .notLaunch, _standardInputPipe == nil {
            _standardInputPipe = Pipe()
            process.standardInput = _standardInputPipe
        }
        return _standardInputPipe
    }
    
    public enum State: Equatable {
        case notLaunch
        case running
        case terminated(status: Int, reason: Process.TerminationReason)
        
        public var isTerminated: Bool {
            guard case .terminated = self else {
                return false
            }
            
            return true
        }
    }
    
    public init(
        existingProcess: Process?,
        progressHandler: _AsyncProcess.ProgressHandler = .empty,
        options: [_AsyncProcess.Option]
    ) throws {
        if let existingProcess {
            assert(!existingProcess.isRunning)

            self.process = existingProcess
        } else {
            if Set(options).isSuperset(of: [._useAppleScript, ._useAppleScript]) {
                throw Never.Reason.unsupported
            } else if options.contains(._useAuthorizationExecuteWithPrivileges) {
                self.process = _SecAuthorizedProcess()
            } else if options.contains(._useAppleScript) {
                self.process = _OSAScriptProcess()
            } else {
                self.process = Process()
            }
        }
        
        self.progressHandler = progressHandler
        self.options = options
        
        _registerAndSetUpIO(existingProcess: existingProcess)
    }
    
    public init(
        executableURL: URL?,
        arguments: [String]?,
        environment: [String: String]?,
        currentDirectoryURL: URL?,
        progressHandler: _AsyncProcess.ProgressHandler = .empty,
        options: [_AsyncProcess.Option]
    ) throws {
        if Set(options).isSuperset(of: [._useAppleScript, ._useAppleScript]) {
            self.process = _SecAuthorizedProcess()
        } else if options.contains(._useAuthorizationExecuteWithPrivileges) {
            self.process = _SecAuthorizedProcess()
        } else if options.contains(._useAppleScript) {
            self.process = _OSAScriptProcess()
        } else {
            self.process = Process()
        }

        process.executableURL = executableURL
        process.arguments = arguments
        process.environment = environment
        process.currentDirectoryURL = currentDirectoryURL?._fromURLToFileURL() ?? process.currentDirectoryURL

        self.progressHandler = progressHandler
        self.options = options
                
        _registerAndSetUpIO(existingProcess: nil)
    }
    
    private func _registerAndSetUpIO(existingProcess: Process?) {
        Self.$runningProcesses.withCriticalRegion {
            $0.append(self)
        }
        
        _setUpStdoutStderr(existingProcess: existingProcess)
    }

    private func _setUpStdoutStderr(
        existingProcess: Process?
    ) {
        if let existingProcess {
            assert(process === existingProcess)
        }
        
        if let existingStandardOutputPipe = existingProcess?.standardOutput as? Pipe {
            _standardOutputPipe = .some(existingStandardOutputPipe)
        } else {
            _standardOutputPipe = Pipe()
            process.standardOutput = _standardOutputPipe
        }
        
        if let existingStandardErrorPipe = existingProcess?.standardError as? Pipe {
            _standardErrorPipe = .some(existingStandardErrorPipe)
        } else {
            _standardErrorPipe = Pipe()
            process.standardError = _standardErrorPipe
        }
        
        if _standardOutputPipe == nil {
            runtimeIssue("_standardOutputPipe is nil!")
        }
    }
    
    private func _readDataFromStdoutStderr() async throws {
        if !options.contains(._useAuthorizationExecuteWithPrivileges) {
            try await _readStdoutStderrUntilEnd()
        } else {
            try await _readStdoutStderrUntilEnd(ignoreStderr: true)
        }
    }
    
    private func _spinUntilProcessExit() async {
        while process.isRunning {
            runtimeIssue("The process is expected to have stopped running.")
            
            await Task.yield()
        }
        
        do {
            try Task.checkCancellation()
        } catch {
            do {
                try await terminate()
            } catch {
                runtimeIssue(error)
            }
        }
        
        assert(!process.isRunning)
    }
    
    private func _readStdoutStderrUntilEnd(ignoreStderr: Bool = false) async throws {
        guard let _standardOutputPipe, let _standardErrorPipe else {
            assertionFailure()
            
            return
        }
        
        @MutexProtected
        var workItem: DispatchWorkItem? = nil
        
        @Sendable
        func interruptLater() -> Bool {
            $workItem.withCriticalRegion { workItem in
                workItem?.cancel()
                
                workItem = DispatchWorkItem {
                    guard self.process.isRunning else {
                        runtimeIssue("Process has already exit, nothing to interrupt.")
                        
                        return
                    }
                    
                    self.process.interrupt()
                }
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 90, execute: workItem!)
                
                return true
            }
        }
        
        @Sendable
        func checkTask() -> Bool {
            withUnsafeCurrentTask { task in
                if task?.isCancelled == true {
                    Task {
                        try await self.terminate()
                    }
                    
                    return false
                }
                
                return true
            }
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                while
                    checkTask(),
                    interruptLater(),
                    let data = _standardOutputPipe.fileHandleForReading.availableData.nilIfEmpty()
                {
                    workItem?.cancel()
                    
                    try await self.handle(data: data, forPipe: _standardOutputPipe)
                    
                    await Task.yield()
                }
            }
            
            if !ignoreStderr {
                group.addTask {
                    while
                        _standardErrorPipe._fileDescriptorForReading._isOpen,
                        checkTask(),
                        interruptLater(),
                        let data = _standardErrorPipe.fileHandleForReading.availableData.nilIfEmpty()
                    {
                        workItem?.cancel()
                        
                        try await self.handle(data: data, forPipe: _standardErrorPipe)
                        
                        await Task.yield()
                    }
                }
            }
            
            try await group.waitForAll()
            
            await Task.yield()
        }
        
        workItem?.cancel()
    }
    
    private func _readStdoutStderrUntilEnd2(ignoreStderr: Bool = false) async throws {
        guard let _standardOutputPipe, let _standardErrorPipe else {
            assertionFailure()
            
            return
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await _standardOutputPipe._readToEnd(receiveData: { data in
                    try await self.handle(data: data, forPipe: _standardOutputPipe)
                })
            }
            
            group.addTask {
                try await _standardErrorPipe._readToEnd(receiveData: { data in
                    try await self.handle(data: data, forPipe: _standardErrorPipe)
                })
            }
            
            try await group.waitForAll()
        }
    }
    
    private func handle(
        data: Data,
        forPipe pipe: Pipe?
    ) async throws {
        switch pipe {
            case self._standardOutputPipe:
                _publishers.standardOutputPublisher.send(data)
            case self._standardErrorPipe:
                _publishers.standardErrorPublisher.send(data)
            default:
                break
        }
        
        guard var dataAsString = String(data: data, encoding: String.Encoding.utf8), !dataAsString.isEmpty else {
            return
        }
        
        if pipe == self._standardErrorPipe {
            self._standardErrorString += dataAsString
            
            return
        }
        
        if dataAsString.hasSuffix("\n") {
            dataAsString = self.standardOutputCache + dataAsString
            
            self.standardOutputCache = ""
        } else {
            self.standardOutputCache += dataAsString
            
            dataAsString = ""
        }
        
        if dataAsString.isEmpty {
            return
        }
        
        self._standardOutputString += dataAsString
        
        var progressHandler = self.progressHandler
        
        if case .print = progressHandler {
            progressHandler = .block { text in
                print(text)
            }
        }

        switch progressHandler {
            case let .block(output, error):
                let progress = (pipe == self._standardOutputPipe ? output : error) ?? output
                
                if self.options.splitWithNewLine {
                    for str in dataAsString.split(separator: "\n") {
                        progress(str.trimmingCharacters(in: self.options.trimmingCharacterSet))
                    }
                } else {
                    progress(dataAsString.trimmingCharacters(in: self.options.trimmingCharacterSet))
                }
            case .print:
                fatalError()
        }
    }
    
    @discardableResult
    public func run() async throws -> _ProcessResult {
        if let _result {
            return try _result.get()
        }
        
        guard state != .running else {
            try await processDidExit.enter()
            
            return try _result.unwrap().get()
        }
        
        do {
            try Task.checkCancellation()
            
            try await _run()
            
            await _spinUntilProcessExit()
            
            return try _result.unwrap().get()
        } catch {
            if !Task.isCancelled {
                self._result = .failure(error)
            }
            
            throw error
        }
    }
    
    public func start() async throws {
        let _: Void = run()
        
        try await processDidStart.enter()
    }
    
    private func _run() async throws {
        do {
            if case .print = progressHandler {
                logger.info("\(self.process.executableURL!), args: \(self.process.arguments ?? [])")
            }
            
            _dumpCallStackIfNeeded()
            
            guard !isWaiting else {
                return
            }
            
            isWaiting = true
            
            let readStdoutStderrTask = Task.detached(priority: .high) {
                try await self._readDataFromStdoutStderr()
            }
            
            try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                @MutexProtected
                var didResume: Bool = false
                
                process.terminationHandler = { process in
                    Task.detached(priority: .userInitiated) {
                        await Task.yield()
                        
                        if let terminationError = process.terminationError {
                            continuation.resume(throwing: terminationError)
                        } else {
                            assert(!process.isRunning)
                            
                            continuation.resume()
                        }
                        
                        $didResume.assignedValue = true
                    }
                }
                
                do {
                    _willRunRightAfterThis()
                    
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                }
                
                _didJustExit(didResume: { didResume })
            }
            
            try await readStdoutStderrTask.value
            
            assert(!process.isRunning)
            
            do {
                try _standardOutputPipe?.fileHandleForReading.close()
                try _standardErrorPipe?.fileHandleForReading.close()
                try _standardInputPipe?.fileHandleForWriting.close()
            } catch {
                runtimeIssue("Failed to close a pipe.")
            }
            
            _stashResultAndTeardown(error: nil)
        } catch {
            _stashResultAndTeardown(error: error)
            
            throw error
        }
    }
    
    private func _dumpCallStackIfNeeded() {
        do {
            if Thread._isMainThread {
                let stack = Thread.callStackSymbols
                let tempFile = NSTemporaryDirectory() + "/" + UUID().uuidString
                
                try stack.joined(separator: "\n").write(toFile: tempFile, atomically: true, encoding: .utf8)
            }
        } catch {
            runtimeIssue(error)
        }
    }
    
    private func _willRunRightAfterThis() {
        assert(!process.isRunning)
        
        Task.detached(priority: .userInitiated) { @MainActor in
            while !self.process.isRunning {
                await Task.yield()
                
                try await Task.sleep(.milliseconds(10))
            }
            
            self.processDidStart.open()
        }
    }
    
    private func _didJustExit(didResume: @escaping () -> Bool) {
        Task {
            try await Task.sleep(.milliseconds(200))
            
            await Task.yield()
            
            if !process.isRunning && !didResume() {
                runtimeIssue("\(description) exited.")
            }
        }
    }
    
    @discardableResult
    private func _stashResultAndTeardown(
        error: Error?
    ) -> Result<_ProcessResult, Error> {
        Self.$runningProcesses.withCriticalRegion {
            $0.removeAll(where: { $0 === self })
        }
        
        let progressHandler = self.progressHandler
        let outputString = _standardOutputString.trimmingCharacters(in: options.trimmingCharacterSet)

        switch progressHandler {
            case let .block(outputCall, errorCall):
                if options.reportCompletion {
                    if !outputString.isEmpty {
                        outputCall(outputString)
                    }
                }
                
                let error = _standardErrorString.trimmingCharacters(in: options.trimmingCharacterSet)
                
                if !error.isEmpty {
                    (errorCall ?? outputCall)(error)
                }
            case .print:
                debugPrint(outputString)
        }
        
        let result: Result<_ProcessResult, Error>
        
        if let error {
            result = .failure(error)
        } else {
            result = Result(catching: {
                try _ProcessResult(
                    process: process,
                    stdout: self._standardOutputString,
                    stderr: self._standardErrorString,
                    terminationError: process.terminationError
                )
            })
        }
        
        self._result = result
        
        _publishers.exitPublisher.send(process.terminationStatus)
        
        processDidExit.open()
        
        return result
    }
    
    public func terminate() async throws {
        process.terminate()
    }
}

@available(macCatalyst, unavailable)
extension _AsyncProcess {
    public func _standardOutputPublisher() -> AnyPublisher<Data, Never> {
        _publishers.standardOutputPublisher
            .compactMap({ (data) -> [Just<String>]? in
                String(data: data, encoding: .utf8)?.lines(omittingEmpty: false).map({
                    Just(String($0))
                })
            })
            .flatMap({ Publishers.ConcatenateMany($0) })
            .compactMap({ $0.data(using: .utf8) })
            .eraseToAnyPublisher()
    }
    
    public func _standardErrorPublisher() -> AnyPublisher<Data, Never> {
        _publishers.standardErrorPublisher.eraseToAnyPublisher()
    }
    
    public func _exitPublisher() -> AnyPublisher<Int32, Never> {
        _publishers.exitPublisher.eraseToAnyPublisher()
    }
    
    public func _send(data: Data) throws {
        runtimeIssue("Send not allowed")
    }
    
    public func _terminate() {
        Task {
            try await terminate()
        }
    }
}

extension String {
    /// Converts the string to an escaped version suitable for terminal emulators.
    func toTerminalEscapedString() -> String {
        var escapedString = self
        
        // Replace common special characters with their escape sequences
        let replacements: [String: String] = [
            "\u{1B}": "\\e",      // Escape character
            "\u{07}": "\\a",      // Bell
            "\u{08}": "\\b",      // Backspace
            "\u{0C}": "\\f",      // Formfeed
            "\u{0A}": "\\n",      // Newline
            "\u{0D}": "\\r",      // Carriage return
            "\u{09}": "\\t",      // Horizontal tab
            "\u{0B}": "\\v"       // Vertical tab
        ]
        
        for (character, escapeCode) in replacements {
            escapedString = escapedString.replacingOccurrences(of: character, with: escapeCode)
        }
        
        return escapedString
    }
}

@available(macCatalyst, unavailable)
extension _AsyncProcess {
    public var isRunning: Bool {
        state == .running
    }
    
    public var state: State {
        if process.isRunning {
            return .running
        }
        
        var terminationReason: Process.TerminationReason?
        
        if process is _SecAuthorizedProcess {
            if !processDidStart.isOpen {
                return .notLaunch
            }
        } else {
            if !processDidStart.isOpen && process.processIdentifier == 0 {
                return .notLaunch
            }
        }
        
        terminationReason = process.terminationReason
        
        if let terminationReason = terminationReason {
            return .terminated(
                status: Int(process.terminationStatus),
                reason: terminationReason
            )
        }
        
        return .notLaunch
    }
    
    @_disfavoredOverload
    public func run() {
        Task.detached(priority: .userInitiated) {
            do {
                try await self.run()
            } catch {
                runtimeIssue(error)
            }
        }
    }
    
    public func start(
        completion: @escaping (Result<Void, Error>) -> Void
    ) async throws {
        Task.detached(priority: .userInitiated) {
            let result = await Result(catching: {
                try await self.start()
            })
            
            completion(result)
        }
    }
}

// MARK: - Initializers

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension _AsyncProcess {
    public convenience init(
        executableURL: URL?,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environmentVariables: [String: String] = [:],
        options: [_AsyncProcess.Option]
    ) throws {
        try self.init(
            existingProcess: nil,
            progressHandler: .empty,
            options: options
        )
        
        self.process.executableURL = executableURL ?? URL(fileURLWithPath: "/bin/zsh")
        self.process.arguments = arguments
        self.process.currentDirectoryURL = currentDirectoryURL?._fromURLToFileURL()
        self.process.environment = environmentVariables
    }
    
    public convenience init(
        launchPath: String?,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environmentVariables: [String: String] = [:],
        options: [_AsyncProcess.Option]
    ) throws {
        try self.init(
            executableURL: launchPath.map({ URL(fileURLWithPath: $0) }),
            arguments: arguments,
            currentDirectoryURL: currentDirectoryURL,
            environmentVariables: environmentVariables,
            options: options
        )
    }
}

// MARK: - Conformances

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension _AsyncProcess: CustomStringConvertible {
    public var description: String {
        Process._makeDescriptionPrefix(
            launchPath: self.process.launchPath,
            arguments: self.process.arguments
        )
    }
}

// MARK: - Internal

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension Array where Element == _AsyncProcess.Option {
    var splitWithNewLine: Bool {
        self.contains {
            if case .splitWithNewLine = $0 {
                return true
            }
            return false
        }
    }
    
    var reportCompletion: Bool {
        self.contains {
            if case .reportCompletion = $0 {
                return true
            }
            return false
        }
    }
    
    var trimmingCharacterSet: CharacterSet {
        var characterSet = CharacterSet()
        self.compactMap { option -> CharacterSet? in
            if case let .trimming(set) = option {
                return set
            }
            return nil
        }
        .forEach {
            characterSet.formUnion($0)
        }
        return characterSet
    }
}

#endif
