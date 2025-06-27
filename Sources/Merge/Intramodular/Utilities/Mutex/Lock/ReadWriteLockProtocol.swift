//
// Copyright (c) Vatsal Manot
//

import Swallow

protocol ReadWriteLockProtocol: Lock {
    func acquireOrBlockForReading()
    func relinquishForReading()
    
    func acquireOrBlockForWriting()
    func relinquishForWriting()
}

protocol ReentrantReadWriteLockProtocol: ReentrantLock {
    func acquireOrBlockForReading()
    func relinquishForReading()
    
    func acquireOrBlockForWriting()
    func relinquishForWriting()
}
