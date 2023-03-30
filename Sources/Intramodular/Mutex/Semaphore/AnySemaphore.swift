//
// Copyright (c) Vatsal Manot
//

import Swallow

public final class AnySemaphore: Semaphore {
    public let base: any Sendable
    
    private let signalImpl: @Sendable (Any) -> (() -> Any)
    private let waitImpl: @Sendable (Any) -> (() -> Any)
    
    public init<S: Semaphore>(_ semaphore: S) {
        self.base = semaphore
        
        signalImpl = { S.signal($0 as! S) }
        waitImpl = { S.wait($0 as! S) }
    }
    
    @discardableResult
    public func signal() -> Any {
        return signalImpl(base)()
    }
    
    @discardableResult
    public func wait() -> Any {
        return waitImpl(base)()
    }
}
