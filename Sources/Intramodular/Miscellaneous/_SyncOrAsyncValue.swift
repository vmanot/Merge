//
// Copyright (c) Vatsal Manot
//

import Swallow

public struct _NonAsyncAndAsyncAccessor<Root, Value> {
    private let _getNonAsync: (Root) throws -> Value
    private let _getAsync: (Root) async throws -> Value
    private let _setNonAsync: (Root, Value) throws -> Void
    private let _setAsync: (Root, Value) async throws -> Void
    
    public struct _NonAsyncBase {
        let get: (Root) throws -> Value
        let set: (Root, Value) throws -> Void
        
        public init(
            get: @escaping (Root) throws -> Value,
            set: @escaping (Root, Value) throws -> Void
        ) {
            self.get = get
            self.set = set
        }
        
        public init(
            get: @escaping () throws -> Value,
            set: @escaping (Value) throws -> Void
        ) where Root == Void {
            self.get = { (root: Void) in
                try get()
            }
            self.set = { (root: Void, newValue: Value) in
                try set(newValue)
            }
        }
    }
    
    public struct _AsyncBase {
        let get: (Root) async throws -> Value
        let set: (Root, Value) async throws -> Void
        
        public init(
            get: @escaping (Root) async throws -> Value,
            set: @escaping (Root, Value) async throws -> Void
        ) {
            self.get = get
            self.set = set
        }
        
        public init(
            get: @escaping () async throws -> Value,
            set: @escaping (Value) async throws -> Void
        ) where Root == Void {
            self.get = { (root: Void) in
                try await get()
            }
            self.set = { (root: Void, newValue: Value) in
                try await set(newValue)
            }
        }
    }
    
    public init(
        nonAsync: _NonAsyncBase,
        async: _AsyncBase
    ) {
        self._getNonAsync = nonAsync.get
        self._getAsync = async.get
        self._setNonAsync = nonAsync.set
        self._setAsync = async.set
    }
}

extension _NonAsyncAndAsyncAccessor where Root == Void {
    public var value: Value {
        get async throws {
            try await self._getAsync(())
        }
    }
    
    public var synchronouslyAccessedValue: Value {
        get async throws {
            try self._getNonAsync(())
        }
    }
    
    public func setValue(_ newValue: Value) async throws {
        try await self._setAsync((), newValue)
    }
    
    public func synchronouslySetValue(_ newValue: Value) throws {
        try self._setNonAsync((), newValue)
    }
}

public enum _SyncOrAsyncValue<Value> {
    case synchronous(Result<Value, Error>)
    case asynchronous(_AsyncPromise<Value, Error>)
    
    public init(_ value: Value) {
        self = .synchronous(value)
    }
    
    public static func synchronous(
        _ value: @autoclosure () throws -> Value
    ) -> Self {
        .synchronous(Result(catching: { try value() }))
    }
    
    public var value: Value {
        get async throws {
            switch self {
                case .synchronous(let value):
                    return try value.get()
                case .asynchronous(let value):
                    return try await value.get()
            }
        }
    }
    
    public var resolvedValue: Value? {
        get throws {
            switch self {
                case .synchronous(let value):
                    return try value.get()
                case .asynchronous(let value):
                    return try value.fulfilledValue
            }
        }
    }
}

extension _SyncOrAsyncValue where Value: Equatable {
    public static func == (lhs: Self, rhs: Value) throws -> Bool {
        try lhs.resolvedValue == rhs
    }
    
    public static func == (lhs: Value, rhs: Self) throws -> Bool {
        try rhs == lhs
    }
}

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
