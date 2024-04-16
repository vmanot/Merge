//
// Copyright (c) Vatsal Manot
//

import Swallow

extension AsyncSequence {
    public func collect() async rethrows -> Array<Element> {
        try await reduce(into: Array<Element>()) {
            $0.append($1)
        }
    }
}

extension AsyncSequence {
    public func first() async rethrows -> Element? {
        try await first { _ in true }
    }
    
    @_disfavoredOverload
    public func first<T>(
        byUnwrapping transform: (Element) throws -> T?
    ) async rethrows -> T? {
        for try await element in self {
            if let match = try transform(element) {
                return match
            }
        }
        
        return nil
    }
    
    @_disfavoredOverload
    public func firstAndOnly<T>(
        byUnwrapping transform: (Element) throws -> T?
    ) async throws -> T? {
        var result: T?
        
        for try await element in self {
            if let match = try transform(element) {
                guard result == nil else {
                    throw _PlaceholderError()
                }
                
                result = match
            }
        }
        
        return result
    }
    
    public func first<T>(ofType type: T.Type) async throws -> T? {
        try await first(byUnwrapping: { $0 as? T })
    }
    
    public func firstAndOnly<T>(ofType type: T.Type) async throws -> T? {
        try await firstAndOnly(byUnwrapping: { $0 as? T })
    }
    
    public func firstAndOnly(
        where predicate: (Element) throws -> Bool
    ) async throws -> Element? {
        try await firstAndOnly(byUnwrapping: { try predicate($0) ? $0 : nil })
    }
}

extension AsyncSequence {
    public func eraseToThrowingStream() -> AsyncThrowingStream<Element, Error> {
        AsyncThrowingStream(self)
    }
}
