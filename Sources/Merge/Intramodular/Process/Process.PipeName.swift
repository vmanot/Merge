//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift
import System

public enum _ProcessPipeName: Codable, Hashable, Sendable {
    case standardInput
    case standardOutput
    case standardError
}

#if os(macOS)

extension Process {
    public typealias PipeName = _ProcessPipeName
}

// MARK: - Supplementary

public protocol _ProcessPipeProviding {
    func pipe(
        named name: Process.PipeName
    ) -> Pipe?
}

extension _ProcessPipeProviding {
    public func name(of pipe: Pipe) throws -> Process.PipeName {
        if pipe === self.pipe(named: .standardInput) {
            return .standardInput
        } else if pipe === self.pipe(named: .standardOutput) {
            return .standardOutput
        } else if pipe === self.pipe(named: .standardError) {
            return .standardError
        } else {
            throw Process.UnrecognizedPipeError.pipe(pipe)
        }
    }
}

extension Process: _ProcessPipeProviding {
    public func pipe(
        named name: PipeName
    ) -> Pipe? {
        switch name {
            case .standardInput:
                return standardInput as? Pipe
            case .standardOutput:
                return standardOutput as? Pipe
            case .standardError:
                return standardError as? Pipe
        }
    }
}

extension _AsyncProcess: _ProcessPipeProviding {
    public typealias PipeName = Process.PipeName
    
    public func pipe(
        named name: Process.PipeName
    ) -> Pipe? {
        switch name {
            case .standardInput:
                return _standardInputPipe
            case .standardOutput:
                return _standardOutputPipe
            case .standardError:
                return _standardErrorPipe
        }
    }
}

// MARK: - Error Handling

extension Process {
    public enum UnrecognizedPipeError: Swift.Error, @unchecked Sendable {
        case pipe(Pipe)
    }
}

#endif
