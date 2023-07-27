//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol _SyncOrAsyncFunction_Type {
    associatedtype Input
    associatedtype Output
    
    func callAsFunction(_ input: Input) throws -> _SyncOrAsyncValue<Output>
}

public enum _SyncOrAsyncFunction<Input, Output>: _SyncOrAsyncFunction_Type {
    case synchronous((Input) throws -> Output)
    case asynchronous((Input) async throws -> Output)
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> _SyncOrAsyncFunction<Input, T> {
        switch self {
            case .synchronous(let fn):
                return .synchronous({ try transform(fn($0)) })
            case .asynchronous(let fn):
                return .asynchronous({ try await transform(fn($0)) })
        }
    }
    
    public init(_ fn: @escaping (Input) throws -> Output) {
        self = .synchronous(fn)
    }
    
    @_disfavoredOverload
    public init(_ fn: @escaping (Input) async throws -> Output) {
        self = .asynchronous(fn)
    }
    
    public func callAsFunction(_ input: Input) -> _SyncOrAsyncValue<Output> {
        switch self {
            case .synchronous(let fn):
                return .synchronous(try fn(input))
            case .asynchronous(let fn):
                return _SyncOrAsyncValue.asynchronous(_AsyncPromise {
                    try await fn(input)
                })
        }
    }
}
