//
// Copyright (c) Vatsal Manot
//

import Swift

@dynamicMemberLookup
public actor ActorIsolated<Value>: Sendable {
    public var value: Value
    
    public init(_ value: Value) {
        self.value = value
    }
    
    public init(_ value: @autoclosure @Sendable () throws -> Value) rethrows {
        self.value = try value()
    }

    public func withCriticalRegion<T>(
        _ body: @Sendable (inout Value) -> T
    ) -> T {
        body(&value)
    }
    
    public subscript<Subject>(
        dynamicMember keyPath: KeyPath<Value, Subject>
    ) -> Subject {
        value[keyPath: keyPath]
    }
}
