//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge
import System

extension Process {
    public convenience init(
        cmd: String,
        environment: [String: String] = [:],
        workingDirectory: String? = nil
    ) {
        self.init()
        
        self.executableURL = URL(fileURLWithPath: "/bin/zsh")
        self.arguments = ["-c", cmd]
        self.environment = ProcessInfo.processInfo.environment.combine(with: environment)
        
        if let workingDirectory = workingDirectory {
            self.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }
    }
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension Process {
    public func runRedirectingAllOutput(
        to sink: ShellExecutionOutputSink
    ) throws {
        try self.redirectAllOutput(to: sink)
        try self.run()
        self.waitUntilExit()
        
        if let terminationError = terminationError {
            throw terminationError
        }
    }
    
    public func runRedirectingAllOutput(to sink: ShellExecutionOutputSink) async throws {
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
    private func redirectAllOutput(to sink: ShellExecutionOutputSink) throws {
        switch sink {
            case .terminal:
                self.redirectAllOutputToTerminal()
            case .file(path: let path):
                try self.redirectAllOutputToFile(path: path)
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
    private func createFile(atPath path: String) throws -> FileHandle {
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
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    private func redirectAllOutputToFile(path: String) throws {
        let fileHandle = try self.createFile(atPath: path)
        self.standardError = fileHandle
        self.standardOutput = fileHandle
    }
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    private func redirectAllOutputToFiles(out: String, err: String) throws {
        self.standardOutput = try self.createFile(atPath: out)
        self.standardError = try self.createFile(atPath: err)
    }
}

extension Process {
    public struct AllOutput {
        public let stdOut: Data
        public let stdErr: Data
        public let terminationError: Process._TerminationError?
    }
    
    public func runReturningAllOutput() throws -> AllOutput {
        let stdOut = PipeBuffer(id: .stdOut)
        self.standardOutput = stdOut.pipe
        
        let stdErr = PipeBuffer(id: .stdErr)
        self.standardError = stdErr.pipe
        
        try self.run()
        self.waitUntilExit()
        
        return AllOutput(
            stdOut: stdOut.closeReturningData(),
            stdErr: stdErr.closeReturningData(),
            terminationError: terminationError
        )
    }
    
    public func runReturningAllOutput() async throws -> AllOutput {
        
        let stdOut = PipeBuffer(id: .stdOut)
        self.standardOutput = stdOut.pipe
        
        let stdErr = PipeBuffer(id: .stdErr)
        self.standardError = stdErr.pipe
        
        return try await withCheckedThrowingContinuation  { (continuation: CheckedContinuation<AllOutput, Error>) in
            
            self.terminationHandler = { process in
                continuation.resume(returning: AllOutput(
                    stdOut: stdOut.closeReturningData(),
                    stdErr: stdErr.closeReturningData(),
                    terminationError: process.terminationError))
            }
            
            do {
                try self.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

extension Process {
    public func runReturningData() throws -> Data {
        
        let stdOut = PipeBuffer(id: .stdOut)
        self.standardOutput = stdOut.pipe
        self.standardError = FileHandle.standardError
        
        try self.run()
        
        self.waitUntilExit()
        
        if let terminationError = terminationError {
            throw terminationError
        } else {
            return stdOut.closeReturningData()
        }
    }
    
    public func runReturningData() async throws -> Data {
        self.standardError = FileHandle.standardError
        
        let stdOut = PipeBuffer(id: .stdOut)
        self.standardOutput = stdOut.pipe
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            self.terminationHandler = { process in
                if let terminationError = process.terminationError {
                    continuation.resume(throwing: terminationError)
                } else {
                    let data = stdOut.closeReturningData()
                    continuation.resume(returning: data)
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

public extension Process {
    func runReturningTrimmedString() throws -> String? {
        try runReturningData().asTrimmedString()
    }
    
    func runReturningTrimmedString() async throws -> String? {
        try await runReturningData().asTrimmedString()
    }
}

private extension Dictionary where Key == String, Value == String {
    func combine(with overrides: [String: String]?) -> [String: String] {
        guard let overrides = overrides else {
            return self
        }
        
        var result = self
        for pair in overrides {
            result[pair.key] = pair.value
        }
        return result
    }
}
