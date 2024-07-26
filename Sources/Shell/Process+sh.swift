//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Merge
internal import Swallow

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func sh(
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) throws -> _ProcessResult {
    announce("Running `\(cmd)`")
    
    return try shq(cmd, environment: environment, workingDirectory: workingDirectory)
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func sh(
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) async throws -> _ProcessResult {
    await announce("Running `\(cmd)`")
    
    return try await shq(cmd, environment: environment, workingDirectory: workingDirectory)
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func sh(
    command: String,
    environment: [String: String] = [:],
    currentDirectoryURL: URL
) async throws -> _ProcessResult {
    return try await sh(
        command,
        environment: environment,
        workingDirectory: currentDirectoryURL.path
    )
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func sh(
    _ sink: Process.StandardOutputSink,
    command: String,
    environment: [String: String] = [:],
    currentDirectoryURL: URL
) async throws {
    try await sh(
        sink,
        command,
        environment: environment,
        workingDirectory: currentDirectoryURL.path
    )
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func sh(
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: URL
) async throws -> _ProcessResult {
    await announce("Running `\(cmd)`")
    
    return try await shq(cmd, environment: environment, workingDirectory: workingDirectory.path)
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func sh<D: Decodable>(
    _ type: D.Type,
    decodedBy jsonDecoder: JSONDecoder = .init(),
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) throws -> D {
    announce("Running `\(cmd)`, decoding `\(type)`")
    
    return try shq(
        type,
        decodedBy: jsonDecoder,
        cmd,
        environment: environment,
        workingDirectory: workingDirectory
    )
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func sh<D: Decodable>(
    _ type: D.Type,
    decodedBy jsonDecoder: JSONDecoder = .init(),
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) async throws -> D {
    await announce("Running `\(cmd)`, decoding `\(type)`")
    
    return try await shq(
        type,
        decodedBy: jsonDecoder,
        cmd,
        environment: environment,
        workingDirectory: workingDirectory
    )
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func sh(
    _ sink: Process.StandardOutputSink,
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) throws {
    switch sink {
        case .terminal:
            announce("Running `\(cmd)`")
            try shq(sink, cmd, environment: environment, workingDirectory: workingDirectory)
            
        case .null:
            announce("Running `\(cmd)`, discarding output")
            try shq(sink, cmd, environment: environment, workingDirectory: workingDirectory)
            
        case .split(let out, let err):
            announce("Running `\(cmd)`, output to `\(out)`, error to `\(err)`")
            try shq(sink, cmd, environment: environment, workingDirectory: workingDirectory)
            
        case .file(let path):
            announce("Running `\(cmd)`, logging to `\(path)`")
            do {
                try shq(sink, cmd, environment: environment, workingDirectory: workingDirectory)
            } catch {
                let underlyingError = error
                
                let logResult = Result {
                    
                    guard let lastFewLines = try sh("tail -n 10 \(path)").stdoutString?
                        .trimmingCharacters(in: .whitespacesAndNewlines), !lastFewLines.isEmpty else {
                        return "<no content in log file>"
                    }
                    
                    return lastFewLines
                }
                
                switch logResult {
                    case .success(let success):
                        throw _ShellProcessExecutionError.errorWithLogInfo(success, underlyingError: underlyingError)
                    case .failure(let failure):
                        throw _ShellProcessExecutionError.openingLogError(failure, underlyingError: underlyingError)
                }
            }
    }
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func sh(
    _ sink: Process.StandardOutputSink,
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) async throws {
    switch sink {
        case .terminal:
            await announce("Running `\(cmd)`")
        case .file(let path):
            await announce("Running `\(cmd)`, logging to `\(path)`")
            do {
                try await shq(sink, cmd, environment: environment, workingDirectory: workingDirectory)
            } catch {
                let underlyingError = error
                
                let logResult: Result<String, Error> = await {
                    do {
                        let lastFewLines = try await sh("tail -n 10 \(path)").stdoutString?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        guard let lastFewLines, !lastFewLines.isEmpty else {
                            return .success("<no content in log file>")
                        }
                        
                        return .success(lastFewLines)
                    } catch {
                        return .failure(error)
                    }
                }()
                
                switch logResult {
                    case .success(let success):
                        throw _ShellProcessExecutionError.errorWithLogInfo(success, underlyingError: underlyingError)
                    case .failure(let failure):
                        throw _ShellProcessExecutionError.openingLogError(failure, underlyingError: underlyingError)
                }
            }
        case .split(let out, let err):
            await announce("Running `\(cmd)`, output to `\(out)`, error to `\(err)`")
        case .null:
            await announce("Running `\(cmd)`, discarding output")
    }
    
    try await shq(sink, cmd, environment: environment, workingDirectory: workingDirectory)
}

private func announce(_ text: String) {
    ("[Sh] " + text + "\n")
        .data(using: .utf8)
        .map(FileHandle.standardError.write)
}

private func announce(_ text: String) async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        ("[Sh] " + text + "\n")
            .data(using: .utf8)
            .map(FileHandle.standardError.write)
        continuation.resume()
    }
}

#endif
