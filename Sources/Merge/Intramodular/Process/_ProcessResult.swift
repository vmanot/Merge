//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import FoundationX
import Swallow

/// A type that represents the result of a running a `Process`.
@Hashable
public final class _ProcessResult: Logging, @unchecked Sendable {
    public let process: Process
    public let stdout: Data
    public let stderr: Data
    public let terminationError: Process.TerminationError?
    
    /// A convenience property to get lines of the standard output, whitespace and newline trimmed.
    public var lines: [String] {
        get throws {
            let result = try stdout.toStringTrimmingWhitespacesAndNewlines().unwrap().lines().map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            
            if result.count == 1, result.first.isNilOrEmpty {
                return []
            }
            
            return result
        }
    }
    
    package init(
        process: Process,
        stdout: Data,
        stderr: Data,
        terminationError: Process.TerminationError?
    ) {
        self.process = process
        self.stdout = stdout
        self.stderr = stderr
        self.terminationError = terminationError
    }
    
    package convenience init(
        process: Process,
        stdout: String,
        stderr: String,
        terminationError: Process.TerminationError?
    ) throws {
        self.init(
            process: process,
            stdout: try stdout.data(),
            stderr: try stderr.data(),
            terminationError: terminationError
        )
    }
    
    public var stdoutString: String? {
        stdout.toStringTrimmingWhitespacesAndNewlines().nilIfEmpty()
    }
    
    public var stderrString: String? {
        stderr.toStringTrimmingWhitespacesAndNewlines().nilIfEmpty()
    }
    
    public func toString() throws -> String {
        try validate()
        
        return try stdoutString.unwrap()
    }
    
    public func validate() throws {
        if let terminationError {
            if let stderrString = stderrString {
                logger.error(stderrString)
            }
            
            throw terminationError
        }
    }
}

extension Process {
    @available(*, deprecated, renamed: "_ProcessResult")
    public typealias AllOutput = _ProcessResult
}

#endif
