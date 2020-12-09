//
// Copyright (c) Vatsal Manot
//

import Swallow

protocol ReadWriteLock: Lock {
    func acquireOrBlockForReading()
    func relinquishForReading()

    func acquireOrBlockForWriting()
    func relinquishForWriting()
}

protocol ReentrantReadWriteLock: ReentrantLock {
    func acquireOrBlockForReading()
    func relinquishForReading()

    func acquireOrBlockForWriting()
    func relinquishForWriting()
}
