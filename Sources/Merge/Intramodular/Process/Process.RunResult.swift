//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// A type that represents the result of a running a `Process`.
@Hashable
public struct _ProcessRunResult: Logging, @unchecked Sendable {
    #if os(macOS) || targetEnvironment(macCatalyst)
    public let process: Process
    #endif
    public let stdout: Data?
    public let stderr: Data?
    public let terminationError: ProcessTerminationError?
    
    #if os(macOS)
    package init(
        process: Process,
        stdout: Data?,
        stderr: Data?,
        terminationError: Process.TerminationError?
    ) {
        self.process = process
        self.stdout = stdout
        self.stderr = stderr
        self.terminationError = terminationError
    }
    #endif
    
    @_transparent
    public func validate() throws {
        if let terminationError {
            if let stderrString = stderrString {
                logger.error(stderrString)
            }
            
            throw terminationError
        }
    }
}

extension _ProcessRunResult {
    /// A convenience property to get lines of the standard output, whitespace and newline trimmed.
    public var lines: [String] {
        get throws {
            let result = try stdout.unwrap().toStringTrimmingWhitespacesAndNewlines().unwrap().lines().map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            
            if result.count == 1, result.first.isNilOrEmpty {
                return []
            }
            
            return result
        }
    }
    
    public var stdoutString: String? {
        stdout?.toStringTrimmingWhitespacesAndNewlines().nilIfEmpty()
    }
    
    public var stderrString: String? {
        stderr?.toStringTrimmingWhitespacesAndNewlines().nilIfEmpty()
    }

    public func toString() throws -> String {
        try validate()
        
        return try stdoutString.unwrap()
    }
}

// MARK: - Extensions

extension _ProcessRunResult {
    private enum DecodingError: Swift.Error {
        case dataIsEmpty
    }

    public func decode<T: Decodable>(
        _ type: T.Type,
        using decoder: JSONDecoder = .init()
    ) throws -> T {
        do {
            let data: Data = try stdout.unwrap()
            
            guard !data.isEmpty else {
                throw DecodingError.dataIsEmpty
            }
            
            let result: T = try decoder.decode(type, from: data)
            
            return result
        } catch {
            throw error
        }
    }
}

// MARK: - Initializers

#if os(macOS) || targetEnvironment(macCatalyst)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension _ProcessRunResult {
    package init(
        process: Process,
        stdout: String?,
        stderr: String?,
        terminationError: Process.TerminationError?
    ) throws {
        self.init(
            process: process,
            stdout: try stdout?.data(),
            stderr: try stderr?.data(),
            terminationError: terminationError
        )
    }
}
#endif

// MARK: - Supplementary

#if os(macOS)
extension Process {
    public typealias RunResult = _ProcessRunResult
}
#endif

// MARK: - Deprecated

@available(*, deprecated, renamed: "Process.RunResult")
public typealias _ProcessResult = _ProcessRunResult

#if os(macOS)
extension Process {
    @available(*, deprecated, renamed: "Process.RunResult")
    public typealias AllOutput = Process.RunResult
}

#endif
