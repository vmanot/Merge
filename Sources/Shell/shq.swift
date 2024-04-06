//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

/// Run a shell command. Useful for obtaining small bits of output
/// from a shell program
///
/// Does not announce the command it is about to execute.
/// To get an announcement, use `sh`
///
/// Arguments:
/// - `cmd` the shell command to run
/// - `environment` a dictionary of enviroment variables to merge
///     with the enviroment of the current `Process`
/// - `workingDirectory` the directory where to run the command
///
/// Returns:
/// - `String?` of whatever is in the standard output buffer.
///     Calls `.trimmingCharacters(in: .whitespacesAndNewlines)`
///
public func shq(
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) throws -> String?  {
    return try Process(cmd: cmd, environment: environment, workingDirectory: workingDirectory)
        .runReturningData()
        .asTrimmedString()
}

/// async version of the method with the same signature
public func shq(
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) async throws -> String?  {
    return try await Process(cmd: cmd, environment: environment, workingDirectory: workingDirectory)
        .runReturningData()
        .asTrimmedString()
}


/// Run a shell command, and parse the output as JSON
///
public func shq<D: Decodable>(
    _ type: D.Type,
    decodedBy jsonDecoder: JSONDecoder = .init(),
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) throws -> D {
    try Process(cmd: cmd, environment: environment, workingDirectory: workingDirectory)
        .runReturningData()
        .asJSON(decoding: type, using: jsonDecoder)
}

/// Asynchronously, run a shell command, and parse the output as JSON
///
public func shq<D: Decodable>(
    _ type: D.Type,
    decodedBy jsonDecoder: JSONDecoder = .init(),
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) async throws -> D {
    let data = try await Process(
        cmd: cmd,
        environment: environment,
        workingDirectory: workingDirectory)
        .runReturningData()
    return try data.asJSON(decoding: type, using: jsonDecoder)
}

/// Run a shell command, sending output to the terminal or a file.
/// Useful for long running shell commands like `xcodebuild`
///
/// Does not announce the command it is about to execute.
/// To get an announcement, use `sh`
///
/// Arguments:
/// - `sink` where to redirect output to, either `.terminal` or `.file(path)`
/// - `cmd` the shell command to run
/// - `environment` a dictionary of enviroment variables to merge
///     with the enviroment of the current `Process`
/// - `workingDirectory` the directory where to run the command
///
@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func shq(
    _ sink: ShellExecutionOutputSink,
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) throws {
    try Process(
        cmd: cmd,
        environment: environment,
        workingDirectory: workingDirectory
    )
    .runRedirectingAllOutput(to: sink)
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public func shq(
    _ sink: ShellExecutionOutputSink,
    _ cmd: String,
    environment: [String: String] = [:],
    workingDirectory: String? = nil
) async throws {
    try await Process(
        cmd: cmd,
        environment: environment,
        workingDirectory: workingDirectory
    )
    .runRedirectingAllOutput(to: sink)
}
