//
// Copyright (c) Vatsal Manot
//

import Swift

public protocol _MaybeAsyncProtocol {
    var _isKnownAsync: Bool? { get }
    
    func _resolveToNonAsync() async throws -> Self
}

// MARK: - Implementation

extension _MaybeAsyncProtocol {
    public var _isKnownAsync: Bool? {
        nil
    }
}

// MARK: - Supplementary

public func _resolveMaybeAsync<T>(_ x: T) async throws -> T {
    if let x = x as? _MaybeAsyncProtocol {
        return try await x._resolveToNonAsync() as! T
    } else {
        return x
    }
}

// MARK: - Error Handling

public enum _MaybeAsyncProtocolError: Error {
    case needsResolving
}
