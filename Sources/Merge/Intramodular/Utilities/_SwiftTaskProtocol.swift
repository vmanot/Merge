//
// Copyright (c) Vatsal Manot
//

import Swift

public protocol _SwiftTaskProtocol<Success, Failure>: Sendable {
    associatedtype Success
    associatedtype Failure
    
    func cancel()
}

extension Task: _SwiftTaskProtocol {
    
}
