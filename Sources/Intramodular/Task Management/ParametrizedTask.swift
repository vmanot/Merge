//
// Copyright (c) Vatsal Manot
//

import Swift

/// A task that is parametrized by some input.
public protocol ParametrizedTask: TaskProtocol {
    associatedtype Input
    
    func receive(_: Input) throws
}
