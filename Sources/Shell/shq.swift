//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swallow

public func shq(
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) throws -> String?  {
    return try Process(
        command: cmd,
        environment: environment,
        currentDirectoryPath: workingDirectory
    )
    .runReturningData()
    .toStringTrimmingWhitespacesAndNewlines()
}

public func shq(
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) async throws -> String?  {
    return try await Process(
        command: cmd,
        environment: environment,
        currentDirectoryPath: workingDirectory
    )
    .runReturningData()
    .toStringTrimmingWhitespacesAndNewlines()
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
    .runReturningData()
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
    
    return try await process.runReturningData().decode(type, using: jsonDecoder)
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

// MARK: - Internal

extension Process {
    fileprivate func runReturningTrimmedString() throws -> String? {
        try runReturningData().toStringTrimmingWhitespacesAndNewlines()
    }
    
    fileprivate func runReturningTrimmedString() async throws -> String? {
        try await runReturningData().toStringTrimmingWhitespacesAndNewlines()
    }
}

#endif
