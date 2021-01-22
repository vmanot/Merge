//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension NSLock: TestableLock {

}

extension NSRecursiveLock: ReentrantLock, TestableLock {

}
