//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Merge
internal import Swallow

public func shq(
    _ cmd: String,
    arguments: [Process.ArgumentLiteral] = [],
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) throws -> _ProcessResult {
    return try Process(
        command: cmd,
        arguments: arguments,
        environment: environment,
        currentDirectoryPath: workingDirectory
    )
    ._runSync()
}

@_disfavoredOverload
public func shq(
    _ cmd: String,
    arguments: [String],
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) throws -> _ProcessResult {
    try shq(
        cmd,
        arguments: arguments.map(Process.ArgumentLiteral.init(stringLiteral:)),
        environment: environment,
        workingDirectory: workingDirectory
    )
}

public func shq(
    _ cmd: String,
    arguments: [String],
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) throws {
    try shq(
        cmd,
        arguments: arguments.map(Process.ArgumentLiteral.init(stringLiteral:)),
        environment: environment,
        workingDirectory: workingDirectory
    )
    .validate()
}

public func shq(
    _ cmd: String,
    arguments: [Process.ArgumentLiteral] = [],
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) async throws -> _ProcessResult  {
    return try await Process(
        command: cmd,
        arguments: arguments,
        environment: environment,
        currentDirectoryPath: workingDirectory
    )
    ._runAsync()
}

@_disfavoredOverload
public func shq(
    _ cmd: String,
    arguments: [String],
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) async throws -> _ProcessResult {
    try await shq(
        cmd,
        arguments: arguments.map(Process.ArgumentLiteral.init(stringLiteral:)),
        environment: environment,
        workingDirectory: workingDirectory
    )
}

public func shq(
    _ cmd: String,
    arguments: [String],
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) async throws  {
    try await shq(
        cmd,
        arguments: arguments,
        environment: environment,
        workingDirectory: workingDirectory
    )
    .validate()
}

public func shq<D: Decodable>(
    _ type: D.Type,
    decodedBy jsonDecoder: JSONDecoder = .init(),
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) throws -> D {
    try Process(
        command: cmd,
        environment: environment,
        currentDirectoryPath: workingDirectory
    )
    ._runSync()
    .stdout
    .decode(type, using: jsonDecoder)
}

public func shq<D: Decodable>(
    _ type: D.Type,
    decodedBy jsonDecoder: JSONDecoder = .init(),
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) async throws -> D {
    let process = Process(
        command: cmd,
        environment: environment,
        currentDirectoryPath: workingDirectory
    )
    
    return try await process._runAsync().stdout.decode(type, using: jsonDecoder)
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func shq(
    _ sink: Process.StandardOutputSink,
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) throws {
    try Process(
        command: cmd,
        environment: environment,
        currentDirectoryPath: workingDirectory
    )
    ._runRedirectingAllOutput(to: sink)
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func shq(
    _ sink: Process.StandardOutputSink,
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) async throws {
    try await Process(
        command: cmd,
        environment: environment,
        currentDirectoryPath: workingDirectory
    )
    ._runAsyncRedirectingAllOutput(to: sink)
}

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
        case .filePath(let path):
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
        case .filePath(let path):
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
