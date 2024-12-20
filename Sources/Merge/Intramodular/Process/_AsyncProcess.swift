//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Foundation
@_spi(Internal) import Swallow
import System

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public class _AsyncProcess: Logging {
    public let options: Set<Option>
    #if os(macOS)
    public let process: Process
    #endif
    
    private let _publishers = _Publishers()
    private let processDidStart = _AsyncGate(initiallyOpen: false)
    private let processDidExit = _AsyncGate(initiallyOpen: false)
    
    @_OSUnfairLocked
    private var isWaiting = false
    
    package var _standardInputPipe: Pipe?
    package var _standardOutputPipe: Pipe?
    package var _standardErrorPipe: Pipe?
    
    @_OSUnfairLocked
    private var _resolvedRunResult: Result<_ProcessRunResult, Error>?
    
    public private(set) var _standardOutputString = ""
    public private(set) var _standardErrorString = ""
        
    #if os(macOS)
    public init(
        existingProcess: Process?,
        options: [_AsyncProcess.Option]?
    ) throws {
        let options: Set<_AsyncProcess.Option> = Set(options ?? [])

        if let existingProcess {
            assert(!existingProcess.isRunning)
            
            self.process = existingProcess
        } else {
            if options.isSuperset(of: [._useAppleScript, ._useAppleScript]) {
                throw Never.Reason.unsupported
            } else if options.contains(._useAuthorizationExecuteWithPrivileges) {
                self.process = _SecAuthorizedProcess()
            } else if options.contains(._useAppleScript) {
                self.process = OSAScriptProcess()
            } else {
                self.process = Process()
            }
        }
        
        self.options = Set(options)
        
        _registerAndSetUpIO(existingProcess: existingProcess)
    }
    
    public init(
        executableURL: URL?,
        arguments: [String]?,
        environment: [String: String]?,
        currentDirectoryURL: URL?,
        options: [_AsyncProcess.Option]? = nil
    ) throws {
        let options: Set<_AsyncProcess.Option> = Set(options ?? [])
        
        if options.isSuperset(of: [._useAppleScript, ._useAppleScript]) {
            self.process = _SecAuthorizedProcess()
        } else if options.contains(._useAuthorizationExecuteWithPrivileges) {
            self.process = _SecAuthorizedProcess()
        } else if options.contains(._useAppleScript) {
            self.process = OSAScriptProcess()
        } else {
            self.process = Process()
        }
        
        process.executableURL = executableURL
        process.arguments = arguments
        process.environment = environment ?? ProcessInfo.processInfo.environment
        process.currentDirectoryURL = currentDirectoryURL?._fromURLToFileURL() ?? process.currentDirectoryURL

        self.options = options
        
        _registerAndSetUpIO(existingProcess: nil)
    }
    #else
    public init() throws {
        throw Never.Reason.unavailable
    }
    
    
    public init(
        executableURL: URL?,
        arguments: [String]?,
        environment: [String: String]?,
        currentDirectoryURL: URL?,
        options: [_AsyncProcess.Option]? = nil
    ) throws {
        throw Never.Reason.unsupported
    }
    #endif
    
    #if os(macOS)
    private func _registerAndSetUpIO(existingProcess: Process?) {
        Self.$runningProcesses.withCriticalRegion {
            $0.append(self)
        }
        
        _setUpStdinStdoutStderr(existingProcess: existingProcess)
    }
    #endif
}

#if os(macOS) || targetEnvironment(macCatalyst)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension _AsyncProcess {
    public var isRunning: Bool {
        state == .running
    }
    
    #if os(macOS)
    public var state: State {
        if process.isRunning {
            return .running
        }
        
        var terminationReason: ProcessTerminationError?
        
        if process is _SecAuthorizedProcess {
            if !processDidStart.isOpen {
                return .notLaunch
            }
        } else {
            if !processDidStart.isOpen && process.processIdentifier == 0 {
                return .notLaunch
            }
        }
        
        terminationReason = ProcessTerminationError(_from: process)
        
        if let terminationReason = terminationReason {
            return .terminated(
                status: Int(process.terminationStatus),
                reason: terminationReason.reason
            )
        }
        
        return .notLaunch
    }
    #else
    public var state: State {
        return .notLaunch
    }
    #endif

    public var standardInputPipe: Pipe? {
        #if os(macOS)
        if state == .notLaunch, _standardInputPipe == nil {
            _standardInputPipe = Pipe()
            process.standardInput = _standardInputPipe
        }
        return _standardInputPipe
        #else
        fatalError(.unsupported)
        #endif
    }

    @discardableResult
    public func run() async throws -> _ProcessRunResult {
        #if os(macOS)
        if let _resolvedRunResult {
            return try _resolvedRunResult.get()
        }
        
        guard state != .running else {
            try await processDidExit.enter()
            
            return try _resolvedRunResult.unwrap().get()
        }
        
        do {
            try Task.checkCancellation()
            
            try await _run()
            
            await _spinUntilProcessExit()
            
            return try _resolvedRunResult.unwrap().get()
        } catch {
            if !Task.isCancelled {
                self._resolvedRunResult = .failure(error)
            }
            
            throw error
        }
        #else
        fatalError(.unsupported)
        #endif
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
    
    public func start() async throws {
        let _: Void = run()
        
        try await processDidStart.enter()
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

    public func terminate() async throws {
        #if os(macOS)
        process.terminate()
        #else
        fatalError(.unsupported)
        #endif
    }
    
    public func _terminate() {
        Task {
            try await terminate()
        }
    }
}
#endif

#if os(macOS)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension _AsyncProcess {
    private func _setUpStdinStdoutStderr(
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
        
    private func _run() async throws {
        do {
            _dumpCallStackIfNeeded()
            
            guard !isWaiting else {
                return
            }
            
            isWaiting = true
            
            func readData() async throws {
                if !options.contains(._useAuthorizationExecuteWithPrivileges) {
                    try await _readStdoutStderrUntilEnd()
                } else {
                    try await _readStdoutStderrUntilEnd(ignoreStderr: true)
                }
            }

            let readStdoutStderrTask = Task<Void, Error>.detached(priority: .high) {
                try await readData()
            }
            
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    @MutexProtected
                    var didResume: Bool = false
                    
                    process.terminationHandler = { (process: Process) in
                        Task<Void, Never>.detached(priority: .userInitiated) {
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
            } catch {
                runtimeIssue(error)
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
            
            _stashRunResultAndTeardown(error: nil)
        } catch {
            _stashRunResultAndTeardown(error: error)
            
            throw error
        }
    }
    
    private func _readStdoutStderrUntilEnd(
        ignoreStderr: Bool = false
    ) async throws {
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
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 1800, execute: workItem!)
                
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
                    
                    try await self.__handleData(data, forPipe: _standardOutputPipe)
                    
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
                        
                        try await self.__handleData(data, forPipe: _standardErrorPipe)
                        
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
                    try await self.__handleData(data, forPipe: _standardOutputPipe)
                })
            }
            
            group.addTask {
                try await _standardErrorPipe._readToEnd(receiveData: { data in
                    try await self.__handleData(data, forPipe: _standardErrorPipe)
                })
            }
            
            try await group.waitForAll()
        }
    }
    
    private func __handleData(
        _ data: Data,
        forPipe pipe: Pipe
    ) async throws {
        guard !data.isEmpty else {
            return
        }
        
        let pipeName: Process.PipeName = try self.name(of: pipe)
                
        switch pipeName {
            case .standardOutput:
                _publishers.standardOutputPublisher.send(data)
            case .standardError:
                _publishers.standardErrorPublisher.send(data)
            default:
                break
        }
        
        let forwardStdoutStderrToTerminal: Bool = options.contains(where: { $0._stdoutStderrSink == .terminal }) // FIXME: (@vmanot) unhandled cases

        if forwardStdoutStderrToTerminal {
            switch pipeName {
                case .standardOutput:
                    FileHandle.standardOutput.write(data)
                case .standardError:
                    FileHandle.standardOutput.write(data)
                default:
                    break
            }
        }
        
        guard let dataAsString: String = String(data: data, encoding: String.Encoding.utf8), !dataAsString.isEmpty else {
            return
        }
        
        switch pipeName {
            case .standardInput:
                break
            case .standardOutput:
                self._standardOutputString += dataAsString
            case .standardError:
                self._standardErrorString += dataAsString
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
    
    /// Should be called prior to `_stashRunResultAndTeardown`.
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
    private func _stashRunResultAndTeardown(
        error: Error?
    ) -> Result<Process.RunResult, Error> {
        Self.$runningProcesses.withCriticalRegion {
            $0.removeAll(where: { $0 === self })
        }
        
        let result: Result<Process.RunResult, Error>
        
        if let error {
            result = .failure(error)
        } else {
            result = Result(catching: {
                try Process.RunResult(
                    process: process,
                    stdout: self._standardOutputString,
                    stderr: self._standardErrorString,
                    terminationError: process.terminationError
                )
            })
        }
        
        self._resolvedRunResult = result
        
        _publishers.exitPublisher.send(process.terminationStatus)
        
        processDidExit.open()
        
        return result
    }
}
#endif

#if os(macOS) || targetEnvironment(macCatalyst)
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
}
#endif

// MARK: - Conformances

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess: CustomStringConvertible {
    public var description: String {
        #if os(macOS)
        Process._makeDescriptionPrefix(
            launchPath: self.process.launchPath,
            arguments: self.process.arguments
        )
        #else
        fatalError(.unsupported)
        #endif
    }
}

// MARK: - Auxiliary

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    public enum State: Equatable {
        case notLaunch
        case running
        case terminated(status: Int, reason: ProcessTerminationError.Reason)
        
        public var isTerminated: Bool {
            guard case .terminated = self else {
                return false
            }
            
            return true
        }
    }
    
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public enum Option: Hashable {
        case _useAppleScript
        case _useAuthorizationExecuteWithPrivileges
        case _forwardStdoutStderr(to: _ProcessStandardOutputSink)
        
        public static var _forwardStdoutStderr: Self {
            ._forwardStdoutStderr(to: .terminal)
        }
        
        public var _stdoutStderrSink: _ProcessStandardOutputSink {
            guard case let ._forwardStdoutStderr(sink) = self else {
                return .null
            }

            return sink
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    @MutexProtected
    public static var runningProcesses = [_AsyncProcess]()
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    struct _Publishers {
        let standardOutputPublisher = ReplaySubject<Data, Never>()
        let standardErrorPublisher = ReplaySubject<Data, Never>()
        let exitPublisher = ReplaySubject<Int32, Never>()
    }
}

// MARK: - Helpers

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
