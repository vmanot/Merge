//
// Copyright (c) Vatsal Manot
//

import _Concurrency
import Swift

/// A protocol for `_Concurrency.Task` to conform to.
public protocol _SwiftTaskProtocol<Success, Failure>: Sendable {
    associatedtype Success
    associatedtype Failure
    
    func cancel()
}

extension Task: _SwiftTaskProtocol {
    
}
