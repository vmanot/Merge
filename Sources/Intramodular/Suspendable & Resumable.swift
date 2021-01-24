//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol Suspendable {
    func suspend() throws
}

public protocol Resumable {
    func resume() throws
}
