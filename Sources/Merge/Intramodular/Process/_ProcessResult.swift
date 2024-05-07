//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import FoundationX
import Swallow

public final class _ProcessResult: @unchecked Sendable {
    public let process: Process
    public let stdout: Data
    public let stderr: Data
    public let terminationError: Process.TerminationError?
    
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
        stdout.toStringTrimmingWhitespacesAndNewlines()
    }
    
    public var stderrString: String? {
        stderr.toStringTrimmingWhitespacesAndNewlines()
    }
    
    public func validate() throws {
        if let terminationError {
            throw terminationError
        }
    }
}

extension Process {
    @available(*, deprecated, renamed: "_ProcessResult")
    public typealias AllOutput = _ProcessResult
}

#endif
