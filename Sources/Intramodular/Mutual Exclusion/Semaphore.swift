//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol Semaphore: Mutex {
    associatedtype SignalResult
    associatedtype WaitResult

    @discardableResult
    func signal() -> SignalResult
    @discardableResult
    func wait() -> WaitResult
}

// MARK: - Extensions -

extension Semaphore {
    public func wait(while predicate: @autoclosure () throws -> Bool) rethrows {
        while try predicate() {
            wait()
        }
    }
}
