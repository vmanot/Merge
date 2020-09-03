//
// Copyright (c) Vatsal Manot
//

import Swallow

protocol ReadWriteLock: Lock {
    @discardableResult
    func acquireOrBlockForReading() -> AcquireResult
    @discardableResult
    func relinquishForReading() -> ReleaseResult

    @discardableResult
    func acquireOrBlockForWriting() -> AcquireResult
    @discardableResult
    func relinquishForWriting() -> ReleaseResult
}

protocol ReentrantReadWriteLock: ReentrantLock {
    @discardableResult
    func acquireOrBlockForReading() -> AcquireResult
    @discardableResult
    func relinquishForReading() -> ReleaseResult

    @discardableResult
    func acquireOrBlockForWriting() -> AcquireResult
    @discardableResult
    func relinquishForWriting() -> ReleaseResult
}
