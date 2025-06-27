//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift
import SwiftUI

extension Publisher {
    @inlinable
    public func publish<Root>(
        to keyPath: ReferenceWritableKeyPath<Root, Result<Output, Error>>,
        on object: Root
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: nil,
            receiveOutput: {
                object[keyPath: keyPath] = .success($0)
            },
            receiveCompletion: {
                if case let .failure(error) = $0 {
                    object[keyPath: keyPath] = .failure(error)
                }
            },
            receiveCancel: nil,
            receiveRequest: nil
        )
    }
    
    @inlinable
    public func publish<Root>(
        to keyPath: ReferenceWritableKeyPath<Root, Result<Output, Failure>>,
        on object: Root
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: nil,
            receiveOutput: {
                object[keyPath: keyPath] = .success($0)
            },
            receiveCompletion: {
                if case let .failure(error) = $0 {
                    object[keyPath: keyPath] = .failure(error)
                }
            },
            receiveCancel: nil,
            receiveRequest: nil
        )
    }
    
    @inlinable
    public func publish<Root>(
        to keyPath: ReferenceWritableKeyPath<Root, Result<Output, Error>?>,
        on object: Root
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: nil,
            receiveOutput: {
                object[keyPath: keyPath] = .success($0)
            },
            receiveCompletion: {
                if case let .failure(error) = $0 {
                    object[keyPath: keyPath] = .failure(error)
                }
            },
            receiveCancel: nil,
            receiveRequest: nil
        )
    }
    
    @inlinable
    public func publish<Root>(
        to keyPath: ReferenceWritableKeyPath<Root, Result<Output, Failure>?>,
        on object: Root
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: nil,
            receiveOutput: {
                object[keyPath: keyPath] = .success($0)
            },
            receiveCompletion: {
                if case let .failure(error) = $0 {
                    object[keyPath: keyPath] = .failure(error)
                }
            },
            receiveCancel: nil,
            receiveRequest: nil
        )
    }
}

extension Publisher where Failure == Never {
    @inlinable
    public func publish<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on object: Root) -> Publishers.HandleEvents<Self> {
        handleOutput {
            object[keyPath: keyPath] = $0
        }
    }
    
    @inlinable
    public func publish<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output?>, on object: Root) -> Publishers.HandleEvents<Self> {
        handleOutput {
            object[keyPath: keyPath] = $0
        }
    }
}

extension Publisher where Failure == Error {
    @inlinable
    public func publish<Root>(
        to keyPath: ReferenceWritableKeyPath<Root, Result<Output, Error>>,
        on object: Root
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: nil,
            receiveOutput: {
                object[keyPath: keyPath] = .success($0)
            },
            receiveCompletion: {
                if case let .failure(error) = $0 {
                    object[keyPath: keyPath] = .failure(error)
                }
            },
            receiveCancel: nil,
            receiveRequest: nil
        )
    }
    
    @inlinable
    public func publish<Root>(
        to keyPath: ReferenceWritableKeyPath<Root, Result<Output, Error>?>,
        on object: Root
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: nil,
            receiveOutput: {
                object[keyPath: keyPath] = .success($0)
            },
            receiveCompletion: {
                if case let .failure(error) = $0 {
                    object[keyPath: keyPath] = .failure(error)
                }
            },
            receiveCancel: nil,
            receiveRequest: nil
        )
    }
}

extension Publisher {
    @inlinable
    public func publish(
        to result: Binding<Result<Output, Error>>
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: nil,
            receiveOutput: {
                result.wrappedValue = .success($0)
            },
            receiveCompletion: {
                if case let .failure(error) = $0 {
                    result.wrappedValue = .failure(error)
                }
            },
            receiveCancel: nil,
            receiveRequest: nil
        )
    }
    
    @inlinable
    public func publish(
        to result: Binding<Result<Output, Error>?>
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: nil,
            receiveOutput: {
                result.wrappedValue = .success($0)
            },
            receiveCompletion: {
                if case let .failure(error) = $0 {
                    result.wrappedValue = .failure(error)
                }
            },
            receiveCancel: nil,
            receiveRequest: nil
        )
    }
}
