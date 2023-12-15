//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A type that exports some set of dependencies.
///
/// These exported dependencies are consumed in operations such as `withDependencies(from: ...) { ... }` etc.
public protocol DependenciesExporting {
    var exportedDependencies: Dependencies { get }
}

/// This is a marker property wrapper.
///
/// Other property wrappers use it at runtime to modify their behavior appropriately.
@propertyWrapper
public struct Volatile<T>: MutablePropertyWrapper {
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

extension Volatile: Equatable where T: Equatable {
    
}

extension Volatile: Hashable where T: Hashable {
    
}

extension Volatile: Sendable where T: Sendable {
    
}
