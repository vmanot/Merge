//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swift
import System

public class _AsyncProcess: CustomStringConvertible {
    public enum ProgressHandler {
        public typealias Block = (_ text: String) -> Void
        public enum ScriptOption: Equatable {
            case login
            case delay(_ timeinterval: TimeInterval)
            case waitUntilFinish
            case closeScriptInside
        }
        // use stdout
        case print
        case block(
            output: Block,
            error: Block? = nil
        )
    }
    
    public enum Option: Hashable {
        case _useAuthorizationExecuteWithPrivileges
        case reportCompletion
        case splitWithNewLine
        case trimming(CharacterSet)
    }

    let progressHandler: _AsyncProcess.ProgressHandler
    let options: [Option]
    
    package private(set) var process: Process?
    package var isWaiting = false
    
    static let updateRunningCommandLock = NSLock()
    public static var runningProcesses = [_AsyncProcess]()
    
    private var outPipe: Pipe?
    private var outCache = ""
    public var outputResult = ""
    
    private var errorPipe: Pipe?
    public var errorResult = ""
    
    private var _inputPipe: Pipe?
    
    public var description: String {
        Process._makeDescriptionPrefix(
            launchPath: self.process?.launchPath,
            arguments: self.process?.arguments
        )
    }
    
    var inputPipe: Pipe? {
        if state == .notLaunch, _inputPipe == nil {
            _inputPipe = Pipe()
            process?.standardInput = _inputPipe
        }
        return _inputPipe
    }
    
    enum State: Equatable {
        case notLaunch
        case running
        case terminated(status: Int, reason: Process.TerminationReason)
        case released
    }
    
    var state: State {
        guard let process = process else {
            return .released
            
        }
        if process.isRunning {
            return .running
        }
        
        var terminationReason: Process.TerminationReason?
        
        terminationReason = process.terminationReason
        
        if let terminationReason = terminationReason {
            return .terminated(
                status: Int(process.terminationStatus),
                reason: terminationReason
            )
        }
        
        return .notLaunch
    }
    
    package init(
        progressHandler: _AsyncProcess.ProgressHandler,
        options: [_AsyncProcess.Option]
    ) {
        var progressHandler = progressHandler
        
        if case .print = progressHandler {
            progressHandler = .block { text in
                print(text)
            }
        }

        self.process = options.contains(._useAuthorizationExecuteWithPrivileges) ? _SecAuthorizedProcess() : Process()
        self.progressHandler = progressHandler
        self.options = options
        
        Self.updateRunningCommandLock.lock()
        Self.runningProcesses.append(self)
        Self.updateRunningCommandLock.unlock()
        
        _setUpStdoutStderrPipes()
    }
    
    private func _setUpStdoutStderrPipes() {
        outPipe = Pipe()
        errorPipe = Pipe()
        
        if outPipe == nil {
            runtimeIssue("outPipe is nil!")
        }
        
        process?.standardOutput = outPipe
        process?.standardError = errorPipe
    }
    
    func handlePipes() async throws {
        guard let outPipe, let errorPipe else {
            assertionFailure()
            
            return
        }
        
        weak var process = self.process
        var workItem: DispatchWorkItem?
        
        func interruptLater() -> Bool {
            workItem?.cancel()
            workItem = DispatchWorkItem {
                process?.interrupt()
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 90, execute: workItem!)
            return true
        }
        
        func checkTask() -> Bool {
            withUnsafeCurrentTask { task in
                if task?.isCancelled == true {
                    Task {
                        try await self.forceCancel()
                    }
                    return false
                }
                return true
            }
        }
        
        if !options.contains(._useAuthorizationExecuteWithPrivileges) {
            while checkTask(), interruptLater(),
                  let data = outPipe.fileHandleForReading.availableData.nilIfEmpty()
            {
                workItem?.cancel()
                
                await Task.yield()
                
                try await handle(data: data, for: outPipe)
            }
            
            while
                checkTask(),
                interruptLater(),
                let data = errorPipe.fileHandleForReading.availableData.nilIfEmpty()
            {
                workItem?.cancel()
                
                await Task.yield()
                
                try await handle(data: data, for: errorPipe)
            }
        } else {
            while
                checkTask(),
                let data = outPipe.fileHandleForReading.availableData.nilIfEmpty()
            {
                workItem?.cancel()
                
                await Task.yield()
                
                try await handle(data: data, for: outPipe)
            }
            
        }
        
        workItem?.cancel()
    }
    
    func handle(
        data: Data,
        for pipe: Pipe?
    ) async throws {
        guard var dataAsString = String(data: data, encoding: String.Encoding.utf8), !dataAsString.isEmpty else {
            return
        }
        
        if pipe == self.errorPipe {
            self.errorResult += dataAsString
            return
        }
        if dataAsString.hasSuffix("\n") {
            dataAsString = self.outCache + dataAsString
            self.outCache = ""
        } else {
            self.outCache += dataAsString
            dataAsString = ""
        }
        
        if dataAsString.isEmpty {
            return
        }
        
        if self.options.reportCompletion {
            self.outputResult += dataAsString
        }
        
        switch progressHandler {
            case let .block(output, error):
                let progress = (pipe == self.outPipe ? output : error) ?? output
                
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
    
    package func wait() async throws -> _ProcessResult {
        try await _wait()
        
        try Task.checkCancellation()
        
        let process = try self.process.unwrap()
        
        let output = try _ProcessResult(
            process: process,
            stdout: self.outputResult,
            stderr: self.errorResult,
            terminationError: process.terminationError
        )
                
        return output
    }

    private func _wait() async throws {
        if Thread._isMainThread {
            let stack = Thread.callStackSymbols
            let tempFile = NSTemporaryDirectory() + "/" + UUID().uuidString
            try stack.joined(separator: "\n").write(toFile: tempFile, atomically: true, encoding: .utf8)
        }
        
        guard isWaiting == false else {
            return
        }
        
        isWaiting = true
        
        guard let process else {
            assertionFailure()
            
            throw Never.Reason.illegal
        }
        
        let handlePipesTask1 = Task {
            try await handlePipes()
        }
        
        try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            @MutexProtected
            var didResume: Bool = false
            
            process.terminationHandler = { process in
                if let terminationError = process.terminationError {
                    continuation.resume(throwing: terminationError)
                } else {
                    continuation.resume()
                }
                
                $didResume.assignedValue = true
            }
            
            do {
                assert(!process.isRunning)
                
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
            
            Task {
                try await Task.sleep(.milliseconds(200))
                
                await Task.yield()
                
                if !process.isRunning && !didResume {
                    runtimeIssue("\(description) exited.")
                }
            }
        }
                
        try await handlePipesTask1.value
        
        try await handlePipes()
        
        let progressHandler = self.progressHandler
                
        switch progressHandler {
            case let .block(outputCall, errorCall):
                if options.reportCompletion {
                    let output = outputResult.trimmingCharacters(in: options.trimmingCharacterSet)
                    if !output.isEmpty {
                        outputCall(output)
                    }
                }
                let error = errorResult.trimmingCharacters(in: options.trimmingCharacterSet)
                if !error.isEmpty {
                    (errorCall ?? outputCall)(error)
                }
            case .print:
                fatalError()
        }
        
        Self.updateRunningCommandLock.withLock {
            Self.runningProcesses.removeAll {
                $0 === self
            }
        }
        
        try? outPipe?.fileHandleForReading.close()
        try? errorPipe?.fileHandleForReading.close()
        try? inputPipe?.fileHandleForWriting.close()
    }
    
    public func forceCancel() async throws {
        if let process = process {
            process.terminate()
        }
    }
    
    public var isRunning: Bool {
        state == .running
    }
}

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
