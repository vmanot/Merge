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
extension _AsyncProcess {
    @MutexProtected
    public static var runningProcesses = [_AsyncProcess]()
}

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
    private lazy var standardStreamsBuffer = _StandardStreamsBuffer(
        publishers: publishers,
        options: self.options
    )

    private let publishers = _Publishers()
    private let processDidStart = _AsyncGate(initiallyOpen: false)
    private let processDidExit = _AsyncGate(initiallyOpen: false)
    
    @_OSUnfairLocked
    private var isWaiting = false
    
    package var _standardInputPipe: Pipe?
    package var _standardOutputPipe: Pipe?
    package var _standardErrorPipe: Pipe?
    
    @_OSUnfairLocked
    private var _resolvedRunResult: Result<_ProcessRunResult, Error>?
            
    public var _standardOutputString: String {
        get async throws {
            try await standardStreamsBuffer._standardOutputStringUsingUTF8()
        }
    }
    
    public var _standardErrorString: String {
        get async throws {
            try await standardStreamsBuffer._standardErrorStringUsingUTF8()
        }
    }
    
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
            if options.contains(._useAuthorizationExecuteWithPrivileges) {
                assert(!options.contains(._useAppleScript))
                
                self.process = _SecAuthorizedProcess()
            } else if options.contains(._useAppleScript) {
                assert(!options.contains(._useAuthorizationExecuteWithPrivileges))
                
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
        
        if options.contains(._useAuthorizationExecuteWithPrivileges) {
            assert(!options.contains(._useAppleScript))
            
            self.process = _SecAuthorizedProcess()
        } else if options.contains(._useAppleScript) {
            assert(!options.contains(._useAuthorizationExecuteWithPrivileges))

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
            
            try await _runUnconditionally()
            
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
        Task {
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
        
    private func _runUnconditionally() async throws {
        do {
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
                        _processWillRun()
                        
                        try process.run()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                    
                    _processExited(didResume: { didResume })
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
            
            await _stashRunResultAndTeardownProcess(error: nil)
        } catch {
            await _stashRunResultAndTeardownProcess(error: error)
            
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
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 3000, execute: workItem!)
                
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
                    let data: Data = _standardOutputPipe.fileHandleForReading.availableData.nilIfEmpty()
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
                        let data: Data = _standardErrorPipe.fileHandleForReading.availableData.nilIfEmpty()
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
    
    private func __handleData(
        _ data: Data,
        forPipe pipe: Pipe
    ) async throws {        
        let pipeName: Process.PipeName = try self.name(of: pipe)
        
        await standardStreamsBuffer.record(data: data, forPipe: pipe, pipeName: pipeName)
    }
    
    private func _processWillRun() {
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
    private func _processExited(
        didResume: @escaping () -> Bool
    ) {
        Task {
            try await Task.sleep(.milliseconds(300))
            
            await Task.yield()
            
            if !process.isRunning && !didResume() {
                runtimeIssue("\(description) exited.")
            }
        }
    }
    
    @discardableResult
    private func _stashRunResultAndTeardownProcess(
        error: Error?
    ) async -> Result<Process.RunResult, Error> {
        Self.$runningProcesses.withCriticalRegion {
            $0.removeAll(where: { $0 === self })
        }
        
        let result: Result<Process.RunResult, Error>
        
        if let error {
            result = .failure(error)
        } else {
            result = await Result(
                catching: { () -> Process.RunResult in
                    let stdout: String? = try? await self.standardStreamsBuffer._standardOutputStringUsingUTF8()
                    let stderr: String? = try? await self.standardStreamsBuffer._standardErrorStringUsingUTF8()
                    
                    let result = try Process.RunResult(
                        process: process,
                        stdout: stdout,
                        stderr: stderr,
                        terminationError: process.terminationError.map {
                            ProcessTerminationError(
                                _from: $0.process,
                                stdout: stdout,
                                stderr: stderr
                            )
                        }
                )
                
                return result
            })
        }
        
        self._resolvedRunResult = result
        
        publishers.exitPublisher.send(process.terminationStatus)
        
        processDidExit.open()
        
        return result
    }
}
#endif

#if os(macOS) || targetEnvironment(macCatalyst)
@available(macCatalyst, unavailable)
extension _AsyncProcess {
    public func _standardOutputPublisher() -> AnyPublisher<Data, Never> {
        publishers.standardOutputPublisher
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
        publishers.standardErrorPublisher.eraseToAnyPublisher()
    }
    
    public func _exitPublisher() -> AnyPublisher<Int32, Never> {
        publishers.exitPublisher.eraseToAnyPublisher()
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
    struct _Publishers {
        let standardOutputPublisher = ReplaySubject<Data, Never>()
        let standardErrorPublisher = ReplaySubject<Data, Never>()
        let exitPublisher = ReplaySubject<Int32, Never>()
    }
}
