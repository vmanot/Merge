//
// Copyright (c) Vatsal Manot
//

import Swallow

extension AsyncThrowingStream where Failure == Error {
    public static func just(
        _ element: @escaping () async throws -> Element
    ) -> AsyncThrowingStream<Element, Failure> {
        AsyncThrowingStream<Element, Failure> { continuation in
            Task {
                do {
                    let value = try await element()
                    
                    continuation.yield(value)
                    continuation.finish()
                } catch {
                    continuation.yield(with: .failure(error))
                }
            }
        }
    }
    
    public init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
        var iterator: S.AsyncIterator?
        
        self.init {
            if iterator == nil {
                iterator = sequence.makeAsyncIterator()
            }
            
            return try await iterator?.next()
        }
    }
    
    public init(
        _ makeStream: @escaping () throws -> AsyncThrowingStream,
        onTermination: (@Sendable (Continuation.Termination) -> Void)?
    ) {
        var iterator: AsyncThrowingStream.AsyncIterator?
        
        self.init { () -> Element? in
            do {
                if iterator == nil {
                    iterator = try makeStream().makeAsyncIterator()
                }
                
                let next = try await iterator?.next()
                
                if next == nil {
                    onTermination?(.finished(nil))
                }
                
                return next
            } catch {
                onTermination?(.finished(error))
                
                throw error
            }
        }
    }

    public static func finished(throwing error: Failure? = nil) -> Self {
        Self {
            $0.finish(throwing: error)
        }
    }
}

extension AsyncThrowingStream {
    @_disfavoredOverload
    @inlinable
    public func map<Transformed>(
        _ transform: @escaping @Sendable (Element) async throws -> Transformed
    ) -> AsyncThrowingStream<Transformed, Failure> where Failure == Error {
        map(transform).eraseToThrowingStream()
    }
}

extension AsyncThrowingStream {
    @_disfavoredOverload
    @inlinable public func filter(
        _ isIncluded: @escaping @Sendable (Element) async -> Bool
    ) -> AsyncThrowingStream where Failure == Error {
        filter(isIncluded).eraseToThrowingStream()
    }
}
