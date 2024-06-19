//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Merge
import System

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension Process {
    public func runRedirectingAllOutput(
        to sink: Process.StandardOutputSink
    ) throws {
        try self.redirectAllOutput(to: sink)
        try self.run()
        self.waitUntilExit()
        
        if let terminationError = terminationError {
            throw terminationError
        }
    }
    
    public func runRedirectingAllOutput(
        to sink: Process.StandardOutputSink
    ) async throws {
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
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    private func redirectAllOutput(
        to sink: Process.StandardOutputSink
    ) throws {
        switch sink {
            case .terminal:
                self.redirectAllOutputToTerminal()
            case .file(path: let path):
                try self.setStandardOutputAndError(filePath: path)
            case .split(let out, err: let err):
                try self.redirectAllOutputToFiles(out: out, err: err)
            case .null:
                self.redirectAllOutputToNullDevice()
        }
    }
    
    private func redirectAllOutputToTerminal() {
        self.standardOutput = FileHandle.standardOutput
        self.standardError = FileHandle.standardError
    }
    
    private func redirectAllOutputToNullDevice() {
        self.standardOutput = FileHandle.nullDevice
        self.standardError = FileHandle.nullDevice
    }
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    private func setStandardOutputAndError(
        filePath: String
    ) throws {
        let fileHandle = try self.createFile(atPath: filePath)
        
        self.standardOutput = fileHandle
        self.standardError = fileHandle
    }
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    private func redirectAllOutputToFiles(
        out: String,
        err: String
    ) throws {
        self.standardOutput = try self.createFile(atPath: out)
        self.standardError = try self.createFile(atPath: err)
    }
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    private func createFile(
        atPath path: String
    ) throws -> FileHandle {
        let directories = FilePath(path).lexicallyNormalized().removingLastComponent()
        
        try FileManager.default.createDirectory(atPath: directories.string, withIntermediateDirectories: true)
        
        guard FileManager.default.createFile(atPath: path, contents: Data()) else {
            struct CouldNotCreateFile: Error {
                let path: String
            }
            
            throw CouldNotCreateFile(path: path)
        }
        
        guard let fileHandle = FileHandle(forWritingAtPath: path) else {
            struct CouldNotOpenFileForWriting: Error {
                let path: String
            }
            
            throw CouldNotOpenFileForWriting(path: path)
        }
        
        return fileHandle
    }
}

extension Process {    
    public func _runSync() throws -> _ProcessResult {
        let stdout = _UnsafePipeBuffer(id: .stdout)
        let stderr = _UnsafePipeBuffer(id: .stderr)
        
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
        let stdout = _AsyncUnsafePipeBuffer(id: .stdout)
        let stderr = _AsyncUnsafePipeBuffer(id: .stderr)
        
        self.standardOutput = await stdout.pipe
        self.standardError = await stderr.pipe
        
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
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            self.terminate()
        }
    }
}

#endif
