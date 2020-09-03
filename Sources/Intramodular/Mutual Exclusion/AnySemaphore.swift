//
// Copyright (c) Vatsal Manot
//

import Swallow

public class AnySemaphore: Semaphore {
    public let base: Any
    
    private let signalImpl: ((Any) -> (() -> Any))
    private let waitImpl: ((Any) -> (() -> Any))
    
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
