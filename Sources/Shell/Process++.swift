//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Merge
import System

extension Process {
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    func _runRedirectingAllOutput(
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
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    func _runAsyncRedirectingAllOutput(
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
    
    public func _runSync() throws -> _ProcessResult {
        _installSigintIfNeeded()
        
        let stdout = _UnsafeStandardOutputOrErrorPipeBuffer(id: .stdout)
        let stderr = _UnsafeStandardOutputOrErrorPipeBuffer(id: .stderr)
        
        self.standardOutput = stdout.pipe
        self.standardError = stderr.pipe
        
        try self.run()
        
        self.waitUntilExit()
        
        return _ProcessResult(
            process: self,
            stdout: try stdout.closeReturningData(),
            stderr: try stderr.closeReturningData(),
            terminationError: terminationError
        )
    }
    
    public func _runAsync() async throws -> _ProcessResult {
        _installSigintIfNeeded()
        
        let stdout = _UnsafeAsyncStandardOutputOrErrorPipeBuffer(id: .stdout)
        let stderr = _UnsafeAsyncStandardOutputOrErrorPipeBuffer(id: .stderr)
        
        self.standardOutput = await stdout.pipe
        self.standardError = await stderr.pipe
        
        let isRunning = _OSUnfairLocked<Bool>(wrappedValue: false)
        
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation  { (continuation: CheckedContinuation<_ProcessResult, Error>) in
                self.terminationHandler = { process in
                    _Concurrency.Task {
                        do {
                            continuation.resume(
                                returning: _ProcessResult(
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
}

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

#endif
