//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public actor _AsyncVolleyball<Value>: Sendable {
    private let mutex = _AsyncActorSemaphore.Lock()
    private var stream = AsyncPassthroughStream<Value>()
    
    public var value: Value
    
    public func withCriticalRegion(_ body: (inout Value) -> Void) async {
        await acquire()
        
        body(&value)
        
        stream.send(value)
        
        await relinquish()
    }
    
    public func update(_ value: Value) async {
        await withCriticalRegion {
            $0 = value
        }
    }
    
    public init(_ value: Value) {
        self.value = value
    }
    
    private func acquire() async {
        await mutex.acquire()
    }
    
    private func relinquish() async {
        await mutex.relinquish()
        
        stream.finish()
        
        stream = .init()
    }
}

extension _AsyncVolleyball {
    public func changesUntilRelinquished() async throws -> AsyncThrowingStream<Value, Error> {
        try await mutex.acquireOrFail()
        
        var iterator = await stream.makeAsyncIterator()
        
        let stream = AsyncThrowingStream(unfolding: {
            try await iterator.next()
        })
        
        await mutex.relinquish()
        
        return stream
    }
}
