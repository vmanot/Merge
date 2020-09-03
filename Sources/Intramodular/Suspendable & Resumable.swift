//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol Suspendable: ReferenceType {
    func suspend()
}

public protocol Resumable: ReferenceType {
    func resume()
}
