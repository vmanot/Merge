//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol SemaphoreProtocol: MutexProtocol {
    associatedtype WaitResult
    associatedtype SignalResult

    @discardableResult
    func wait() -> WaitResult

    @discardableResult
    func signal() -> SignalResult
}

// MARK: - Deprecated

@available(*, deprecated, renamed: "SemaphoreProtocol")
public typealias Semaphore = SemaphoreProtocol
