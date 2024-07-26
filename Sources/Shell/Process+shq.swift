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
    .runRedirectingAllOutput(to: sink)
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
    .runRedirectingAllOutput(to: sink)
}

#endif
