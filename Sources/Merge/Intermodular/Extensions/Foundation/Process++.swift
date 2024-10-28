//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Combine
import Dispatch
import Foundation
import Swift
import System

extension Process {
    fileprivate static var _sigintSource: DispatchSourceSignal? = nil
    fileprivate static var _sigintSourceProcesses: [Process] = []
    
    fileprivate func _installSigintIfNeeded() {
        guard
            Self._sigintSource == nil
        else {
            return
        }
        
        signal(SIGINT, SIG_IGN)
        
        Self._sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        Self._sigintSource?.setEventHandler {
            Self._sigintSourceProcesses.forEach {
                $0.terminate()
            }
            
            exit(-1)
        }
        
        Self._sigintSource?.resume()
    }
}

extension Process {
    func pipeStandardOutput<S: Subject>(
        on queue: DispatchQueue,
        to sink: S
    ) -> DispatchSourceRead where S.Output == String {
        let pipe = Pipe()
        
        standardOutput = pipe
        
        let source = DispatchSource.makeReadTextSource(pipe: pipe, queue: queue, sink: sink, encoding: .utf8)
        
        source.activate()
        
        return source
    }
    
    func pipeStandardError<S: Subject>(
        on queue: DispatchQueue,
        to sink: S
    ) -> DispatchSourceRead where S.Output == String {
        let pipe = Pipe()
        
        standardError = pipe
        
        let source = DispatchSource.makeReadTextSource(pipe: pipe, queue: queue, sink: sink, encoding: .utf8)
        
        source.activate()
        
        return source
    }
}

extension Process {
    public static func run(
        command: String,
        arguments: [String]
    ) async throws -> Process.RunResult {
        let process = Process()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        
        return try await process._runAsynchronously()
    }

    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    package func _runSynchronouslyRedirectingAllOutput(
        to sink: Process.StandardOutputSink
    ) throws {
        _installSigintIfNeeded()
        
        try self.redirectAllOutput(to: sink)
        try self.run()
        
        self.waitUntilExit()
        
        if let terminationError = terminationError {
            throw terminationError
        }
    }
        
    public func _runSynchronously() throws -> Process.RunResult {
        _installSigintIfNeeded()
        
        let stdout = _UnsafeStandardOutputOrErrorPipeBuffer(id: .stdout)
        let stderr = _UnsafeStandardOutputOrErrorPipeBuffer(id: .stderr)
        
        self.standardOutput = stdout.pipe
        self.standardError = stderr.pipe
        
        try self.run()
        
        self.waitUntilExit()
        
        return Process.RunResult(
            process: self,
            stdout: try stdout.closeReturningData(),
            stderr: try stderr.closeReturningData(),
            terminationError: terminationError
        )
    }
    
    public func _runAsynchronously() async throws -> Process.RunResult {
        _installSigintIfNeeded()
        
        let stdout = _UnsafeAsyncStandardOutputOrErrorPipeBuffer(id: .stdout)
        let stderr = _UnsafeAsyncStandardOutputOrErrorPipeBuffer(id: .stderr)
        
        self.standardOutput = stdout.pipe
        self.standardError = stderr.pipe
        
        let isRunning = _OSUnfairLocked<Bool>(wrappedValue: false)
        
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation  { (continuation: CheckedContinuation<Process.RunResult, Error>) in
                self.terminationHandler = { process in
                    _Concurrency.Task {
                        do {
                            continuation.resume(
                                returning: Process.RunResult(
                                    process: self,
                                    stdout: try await stdout.closeReturningData(),
                                    stderr: try await stderr.closeReturningData(),
                                    terminationError: process.terminationError
                                )
                            )
                        } catch {
                            assertionFailure(error)
                        }
                    }
                }
                
                do {
                    try self.run()
                    
                    isRunning.wrappedValue = true
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            if isRunning.wrappedValue {
                self.terminate()
            }
        }
    }
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    package func _runAsynchronouslyRedirectingAllOutput(
        to sink: Process.StandardOutputSink
    ) async throws {
        _installSigintIfNeeded()
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try self.redirectAllOutput(to: sink)
            } catch {
                continuation.resume(throwing: error)
                
                return
            }
            
            self.terminationHandler = { process in
                if let terminationError = process.terminationError {
                    continuation.resume(throwing: terminationError)
                } else {
                    continuation.resume()
                }
            }
            
            do {
                try self.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

#endif
