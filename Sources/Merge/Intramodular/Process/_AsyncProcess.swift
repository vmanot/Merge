//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
@_spi(Internal) import Swallow
import System

extension _AsyncProcess {
    public enum Option: Hashable {
        case _useAuthorizationExecuteWithPrivileges
        case reportCompletion
        case splitWithNewLine
        case trimming(CharacterSet)
    }
    
    @MutexProtected
    public static var runningProcesses = [_AsyncProcess]()
}

public class _AsyncProcess: CustomStringConvertible {
    public let progressHandler: _AsyncProcess.ProgressHandler
    public let options: [Option]
    public let process: Process
    
    private let processDidStart = _AsyncGate(initiallyOpen: false)
    private let processDidExit = _AsyncGate(initiallyOpen: false)
    
    @_OSUnfairLocked
    private var isWaiting = false
    private var _standardInputPipe: Pipe?
    private var standardOutputPipe: Pipe?
    private var standardErrorPipe: Pipe?
    
    private var standardOutputCache = ""
    
    @_OSUnfairLocked
    private var _result: Result<_ProcessResult, Error>?
    
    public private(set) var _standardOutputString = ""
    public private(set) var _standardErrorString = ""
    
    public var description: String {
        Process._makeDescriptionPrefix(
            launchPath: self.process.launchPath,
            arguments: self.process.arguments
        )
    }
    
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
    }
    
    public init(
        existingProcess: Process?,
        progressHandler: _AsyncProcess.ProgressHandler = .empty,
        options: [_AsyncProcess.Option]
    ) {
        var progressHandler = progressHandler
        
        if case .print = progressHandler {
            progressHandler = .block { text in
                print(text)
            }
        }
        
        if let existingProcess {
            assert(!existingProcess.isRunning)
        }
        
        self.process = existingProcess ?? (options.contains(._useAuthorizationExecuteWithPrivileges) ? _SecAuthorizedProcess() : Process())
        self.progressHandler = progressHandler
        self.options = options
        
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
            standardOutputPipe = .some(existingStandardOutputPipe)
        } else {
            standardOutputPipe = Pipe()
            process.standardOutput = standardOutputPipe
        }
        
        if let existingStandardErrorPipe = existingProcess?.standardError as? Pipe {
            standardErrorPipe = .some(existingStandardErrorPipe)
        } else {
            standardErrorPipe = Pipe()
            process.standardError = standardErrorPipe
        }
        
        if standardOutputPipe == nil {
            runtimeIssue("standardOutputPipe is nil!")
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
        guard let standardOutputPipe, let standardErrorPipe else {
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
                    let data = standardOutputPipe.fileHandleForReading.availableData.nilIfEmpty()
                {
                    workItem?.cancel()
                    
                    await Task.yield()
                    
                    try await self.handle(data: data, forPipe: standardOutputPipe)
                }
            }
            
            if !ignoreStderr {
                group.addTask {
                    while
                        standardErrorPipe._fileDescriptorForReading._isOpen,
                        checkTask(),
                        interruptLater(),
                        let data = standardErrorPipe.fileHandleForReading.availableData.nilIfEmpty()
                    {
                        workItem?.cancel()
                        
                        await Task.yield()
                        
                        try await self.handle(data: data, forPipe: standardErrorPipe)
                    }
                }
            }
            
            try await group.waitForAll()
        }
        
        workItem?.cancel()
    }
    
    private func _readStdoutStderrUntilEnd2(ignoreStderr: Bool = false) async throws {
        guard let standardOutputPipe, let standardErrorPipe else {
            assertionFailure()
            
            return
        }
            
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await standardOutputPipe._readToEnd(receiveData: { data in
                    try await self.handle(data: data, forPipe: standardOutputPipe)
                })
            }
            
            group.addTask {
                try await standardErrorPipe._readToEnd(receiveData: { data in
                    try await self.handle(data: data, forPipe: standardErrorPipe)
                })
            }
            
            try await group.waitForAll()
        }
    }

    private func handle(
        data: Data,
        forPipe pipe: Pipe?
    ) async throws {
        guard var dataAsString = String(data: data, encoding: String.Encoding.utf8), !dataAsString.isEmpty else {
            return
        }
        
        if pipe == self.standardErrorPipe {
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

        switch progressHandler {
            case let .block(output, error):
                let progress = (pipe == self.standardOutputPipe ? output : error) ?? output
                
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
                try standardOutputPipe?.fileHandleForReading.close()
                try standardErrorPipe?.fileHandleForReading.close()
                try standardInputPipe?.fileHandleForWriting.close()
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
        
        switch progressHandler {
            case let .block(outputCall, errorCall):
                if options.reportCompletion {
                    let output = _standardOutputString.trimmingCharacters(in: options.trimmingCharacterSet)
                    
                    if !output.isEmpty {
                        outputCall(output)
                    }
                }
                
                let error = _standardErrorString.trimmingCharacters(in: options.trimmingCharacterSet)
                
                if !error.isEmpty {
                    (errorCall ?? outputCall)(error)
                }
            case .print:
                fatalError()
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

        processDidExit.open()

        return result
    }
    
    public func terminate() async throws {
        process.terminate()
    }
}

extension _AsyncProcess {
    public var isRunning: Bool {
        state == .running
    }
    
    public var state: State {
        if process.isRunning {
            return .running
        }
        
        var terminationReason: Process.TerminationReason?
        
        if !processDidStart.isOpen && process.processIdentifier == 0 {
            return .notLaunch
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

extension _AsyncProcess {
    public convenience init(
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environmentVariables: [String: String] = [:],
        options: [_AsyncProcess.Option]
    ) {
        self.init(
            existingProcess: nil,
            progressHandler: .empty,
            options: options
        )
        
        self.process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        self.process.arguments = arguments
        self.process.currentDirectoryURL = currentDirectoryURL?._fromURLToFileURL()
        self.process.environment = environmentVariables
    }
}

// MARK: - Auxiliary

extension _AsyncProcess {
    public enum ProgressHandler {
        public typealias Block = (_ text: String) -> Void
        
        public enum ScriptOption: Equatable {
            case login
            case delay(_ timeinterval: TimeInterval)
            case waitUntilFinish
            case closeScriptInside
        }
        
        case print
        case block(
            output: Block,
            error: Block? = nil
        )
        
        public static var empty: Self {
            .block(output: { _ in }, error: nil)
        }
    }
}

// MARK: - Internal

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
