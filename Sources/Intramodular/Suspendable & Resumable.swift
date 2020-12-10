//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol Suspendable {
    func suspend()
}

public protocol Resumable {
    func resume()
}
