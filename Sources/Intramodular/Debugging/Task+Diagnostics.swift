//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol _TaskExecutionDiagnostic {
    associatedtype DiagnosticResult
    
    func scope<T>(
        _ operation: () async -> T
    ) async -> (result: T, diagnosis: _AsyncPromise<DiagnosticResult, Never>)
    
    func scope<T>(
        _ operation: () async throws -> T
    ) async -> (result: Result<T, Error>, diagnosis: _AsyncPromise<DiagnosticResult, Never>)
}

public enum _TaskDiagnostics {
    
}

extension _TaskDiagnostics {
    public struct Log: _TaskExecutionDiagnostic {
        public typealias DiagnosticResult = Void
        
        public enum LogCriteria {
            
        }
        
        public func scope<T>(
            _ operation: () async -> T
        ) async -> (result: T, diagnosis: _AsyncPromise<DiagnosticResult, Never>) {
            let result = await operation()
            
            return (result, .init(()))
        }
        
        public func scope<T>(
            _ operation: () async throws -> T
        ) async -> (result: Result<T, Error>, diagnosis: _AsyncPromise<DiagnosticResult, Never>) {
            let result = await Result(catching: { try await operation() })
            
            return (result, .init(()))
        }
    }
}
