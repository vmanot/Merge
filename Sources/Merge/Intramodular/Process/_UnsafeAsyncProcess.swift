//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swift

public class _UnsafeAsyncProcess {
    public enum Progress {
        public typealias Block = (_ text: String) -> Void
        public enum ScriptOption: Equatable {
            case login
            case delay(_ timeinterval: TimeInterval)
            case waitUntilFinish
            case closeScriptInside
        }
        // use stdout
        case print
        case block(output: Block, error: Block? = nil)
    }
    
    public enum Option: Hashable {
        case _launchAsRoot
        case reportCompletion
        case splitWithNewLine
        case trimming(CharacterSet)
    }

    let progress: _UnsafeAsyncProcess.Progress
    let options: [Option]
    
    package private(set) var process: Process?
    package var isWaiting = false
    
    static let updateRunningCommandLock = NSLock()
    public static var runningProcesses = [_UnsafeAsyncProcess]()
    
    private var outPipe: Pipe?
    private var outCache = ""
    public var outputResult = ""
    
    private var errorPipe: Pipe?
    public var errorResult = ""
    
    private var _inputPipe: Pipe?
    
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
        progress: _UnsafeAsyncProcess.Progress,
        options: [_UnsafeAsyncProcess.Option]
    ) {
        self.process = options.contains(._launchAsRoot) ? _UnsafePrivilegedProcess() : Process()
        self.progress = progress
        self.options = options
        
        Self.updateRunningCommandLock.lock()
        Self.runningProcesses.append(self)
        Self.updateRunningCommandLock.unlock()
        
        if case .block = progress {
            outPipe = Pipe()
            errorPipe = Pipe()
            if outPipe == nil {
                print("outPipe is nil!")
            }
            process?.standardOutput = outPipe
            process?.standardError = errorPipe
        }
    }
    
    func handlePipes() async throws {
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
        
        while
            checkTask(),
            interruptLater(),
            let data = outPipe?.fileHandleForReading.availableData, !data.isEmpty
        {
            workItem?.cancel()
            
            await Task.yield()
            
            try await handle(data: data, for: outPipe)
        }
        
        while
            checkTask(),
            interruptLater(),
            let data = errorPipe?.fileHandleForReading.availableData, !data.isEmpty
        {
            workItem?.cancel()
            
            await Task.yield()

            try await handle(data: data, for: errorPipe)
        }
        
        workItem?.cancel()
    }
    
    func handle(
        data: Data,
        for pipe: Pipe?
    ) async throws {
        guard var strs = String(data: data, encoding: String.Encoding.utf8), !strs.isEmpty else {
            return
        }
        
        if pipe == self.errorPipe {
            self.errorResult += strs
            return
        }
        if strs.hasSuffix("\n") {
            strs = self.outCache + strs
            self.outCache = ""
        } else {
            self.outCache += strs
            strs = ""
        }
        
        if strs.isEmpty {
            return
        }
        
        if self.options.reportCompletion {
            self.outputResult += strs
        } else if case let .block(output, error) = self.progress {
            let progress = (pipe == self.outPipe ? output : error) ?? output
            if self.options.splitWithNewLine {
                for str in strs.split(separator: "\n") {
                    progress(str.trimmingCharacters(in: self.options.trimmingCharacterSet))
                }
            } else {
                progress(strs.trimmingCharacters(in: self.options.trimmingCharacterSet))
            }
        }
    }
    
    package func wait() async throws {
        try await _wait()
        
        try Task.checkCancellation()
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
        
        try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            process.terminationHandler = { process in
                if let terminationError = process.terminationError {
                    continuation.resume(throwing: terminationError)
                } else {
                    continuation.resume()
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        await _expectNoThrow {
            try await handlePipes()
        }
        
        self.process = nil
        
        if case let .block(outputCall, errorCall) = progress {
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

extension Array where Element == _UnsafeAsyncProcess.Option {
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
