//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

public final class RetainUntilCancel<Child: Cancellable>: Cancellable {
    private var instance: RetainUntilCancel?
    private var child: Child?
    
    public init(_ cancellable: Child) {
        instance = self
        child = cancellable
    }
    
    public func cancel() {
        instance = nil
        
        child?.cancel()
        child = nil
    }
}

// MARK: - API -

extension Publisher {
    @discardableResult
    public func retainSink(
        receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void),
        receiveValue: @escaping ((Output) -> Void)
    ) -> RetainUntilCancel<SingleAssignmentAnyCancellable> {
        let _cancellable = SingleAssignmentAnyCancellable()
        let cancellable = RetainUntilCancel(_cancellable)
        
        _cancellable.set(
            handleCancelOrCompletion { _ in
                cancellable.cancel()
            }.sink()
        )
        
        return cancellable
    }
    
    public func retainSink() -> RetainUntilCancel<SingleAssignmentAnyCancellable> {
        retainSink(
            receiveCompletion: { _ in },
            receiveValue: { _  in }
        )
    }
}

extension Publisher where Failure == Never {
    public func retainSink(
        receiveValue: @escaping ((Output) -> Void)
    ) -> RetainUntilCancel<SingleAssignmentAnyCancellable> {
        retainSink(
            receiveCompletion: { _ in },
            receiveValue: receiveValue
        )
    }
}
