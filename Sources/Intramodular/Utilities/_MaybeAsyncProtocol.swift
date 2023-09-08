//
// Copyright (c) Vatsal Manot
//

import Swift

/// Utility protocol for things that might require preheating/one-off resource resolution and are then synchronous to use.
public protocol _MaybeAsyncProtocol {
    var _isKnownAsync: Bool? { get }
    
    func _resolveToNonAsync() async throws -> Self
}

// MARK: - Implementation

extension _MaybeAsyncProtocol {
    public var _isKnownAsync: Bool? {
        nil
    }
    
    public func _resolveToNonAsync() async throws -> Self {
        throw Never.Reason.unimplemented
    }
}

// MARK: - Supplementary

public func _resolveMaybeAsync<T>(_ x: T) async throws -> T {
    do {
        if let x = x as? _MaybeAsyncProtocol {
            return try await x._resolveToNonAsync() as! T
        } else {
            return x
        }
    } catch {
        switch error {
            case _MaybeAsyncProtocolError.noResolutionImplementation:
                return x
            default:
                throw error
        }
    }
}

// MARK: - Error Handling

public enum _MaybeAsyncProtocolError: Equatable, Error {
    case noResolutionImplementation
    case needsResolving
}
