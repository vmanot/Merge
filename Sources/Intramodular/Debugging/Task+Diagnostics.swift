//
// Copyright (c) Vatsal Manot
//

import Swift

public protocol _TaskExecutionDiagnostic {
    associatedtype DiagnosticResult
    
    func scope<T>(
        _ operation: () async -> T
    ) async -> (result: T, diagnosis: AsyncValue<DiagnosticResult>)
    
    func scope<T>(
        _ operation: () async throws -> T
    ) async -> (result: Result<T, Error>, diagnosis: AsyncValue<DiagnosticResult>)
}

public actor AsyncValue<Value> {
    private enum Error: Swift.Error {
        case attemptedToSetValueMoreThanOnce
    }
    
    private let semaphore = AsyncSemaphore()
    private var receivedValue: Value?
    private var didReceiveValue: Task<Void, Never>?
    
    public init() {
        
    }
    
    public init(_ value: Value) {
        self.receivedValue = value
    }
    
    public func set(_ value: Value) async throws {
        guard self.receivedValue == nil else {
            throw Error.attemptedToSetValueMoreThanOnce
        }
        
        self.receivedValue = value
        
        if didReceiveValue != nil {
            await semaphore.signal()
        }
    }
    
    public func get() async -> Value {
        if let receivedValue = receivedValue {
            return receivedValue
        }
        
        if let didReceiveValue = didReceiveValue {
            await didReceiveValue.value
        } else {
            let task = Task.detached {
                await self.semaphore.wait()
            }
            
            didReceiveValue = task
            
            await task.value
        }
        
        return receivedValue!
    }
}

public enum TaskDiagnostics {
    
}

extension TaskDiagnostics {
    public struct Log: _TaskExecutionDiagnostic {
        public typealias DiagnosticResult = Void
        
        public enum LogCriteria {
            
        }
        
        public func scope<T>(
            _ operation: () async -> T
        ) async -> (result: T, diagnosis: AsyncValue<DiagnosticResult>) {
            let result = await operation()
            
            return (result, .init(()))
        }
        
        public func scope<T>(
            _ operation: () async throws -> T
        ) async -> (result: Result<T, Error>, diagnosis: AsyncValue<DiagnosticResult>) {
            let result = await Result(catching: { try await operation() })
            
            return (result, .init(()))
        }
    }
}

private func wrapTask<T>(
    operation: () async -> T,
    with diagnostic: some _TaskExecutionDiagnostic
) async -> T {
    let (result, _) = await diagnostic.scope(operation)
    
    return result
}
