//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension ObservableObject {
    /// Wrap this observable object's `objectWillChange` publisher with a type-eraser.
    public func eraseObjectWillChangePublisher() -> AnyObjectWillChangePublisher {
        .init(from: self)
    }

    public func _opaque_publishToObjectWillChange() throws {
        try cast(objectWillChange, to: (any _opaque_VoidSender).self).send()
    }
}

extension ObservableObject {
    // FIXME: HACK!!!
    @_spi(Private)
    public var _practical_objectDidChange: AnyPublisher<Void, Never> {
        objectWillChange.delay(
            for: .milliseconds(50),
            scheduler: MainThreadScheduler.shared
        )
        .mapTo(())
        .eraseToAnyPublisher()
    }
}

extension ObservableObject {
    @AssociatedObject(.retain(.atomic))
    private var _adHocCancellables: Cancellables = Cancellables()
        
    public func __onReceiveOfValueEmittedBy<T, U>(
        _ publisher: some Publisher<T, U>,
        perform action: @escaping (T) -> Void
    ) {
        let cancellable = SingleAssignmentAnyCancellable()
        let cancellableTypeErased = AnyCancellable(cancellable)
        
        _adHocCancellables.insert(cancellable)
        
        let _cancellable = publisher.sink(
            receiveCompletion: { [weak self] _ in
                self?._adHocCancellables.remove(cancellableTypeErased)
            },
            receiveValue: { (value: T) in
                action(value)
            }
        )
        
        cancellable.set(_cancellable)
    }
    
    public func _onReceiveOfValueEmittedBy<T, U>(
        _ publisher: some Publisher<T, U>,
        perform action: @escaping (T) -> Void
    ) {
        __onReceiveOfValueEmittedBy(publisher, perform: action)
    }
    
    public func _onReceiveOfValueEmittedBy<T: ObservableObject>(
        _ object: T,
        perform action: @escaping () -> Void
    ) {
        __onReceiveOfValueEmittedBy(object.objectWillChange) { _ in
            action()
        }
    }
    
    public func _onReceiveOfValueEmittedBy<T: ObservableObject>(
        _ object: T,
        perform action: @escaping () async throws -> Void
    ) {
        __onReceiveOfValueEmittedBy(object.objectWillChange) { _ in
            Task {
                do {
                    try await action()
                } catch {
                    runtimeIssue(error)
                }
            }
        }
    }
}
