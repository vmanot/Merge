//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol Semaphore: Mutex {
    associatedtype WaitResult
    associatedtype SignalResult

    @discardableResult
    func wait() -> WaitResult

    @discardableResult
    func signal() -> SignalResult
}
