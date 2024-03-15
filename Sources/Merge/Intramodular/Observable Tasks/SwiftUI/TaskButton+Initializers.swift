//
// Copyright (c) Vatsal Manot
//

import Swallow
import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension TaskButton {
    public init(
        action: @escaping () -> AnyTask<Success, Error>,
        @ViewBuilder label: @escaping (TaskStatus<Success, Error>) -> Label
    ) {
        self.action = { action() }
        self.label = label
    }
    
    public init(
        action: @escaping () -> Task<Success, Error>,
        @ViewBuilder label: @escaping (TaskStatus<Success, Error>) -> Label
    ) where Error == Swift.Error {
        self.init(
            action: { () -> AnyTask<Success, Error> in
                action().eraseToAnyTask()
            },
            label: label
        )
    }
    
    public init(
        action: @escaping () -> AnyTask<Success, Error>,
        @ViewBuilder label: () -> Label
    ) {
        let _label = label()
        
        self.action = { action() }
        self.label = { _ in _label }
    }
    
    public init(
        action: @escaping () -> Task<Success, Error>,
        @ViewBuilder label: @escaping () -> Label
    ) where Error == Swift.Error {
        self.init(
            action: { () -> AnyTask<Success, Error> in
                action().eraseToAnyTask()
            },
            label: label
        )
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension TaskButton {
    public init(
        action: @escaping @MainActor @Sendable () async -> Success,
        priority: TaskPriority? = .userInitiated,
        @ViewBuilder label: @escaping (TaskStatus<Success, Error>) -> Label
    ) where Error == Never {
        self.init {
            Task(priority: priority) { @MainActor in
                await action()
            }
            .convertToObservableTask()
        } label: { status in
            label(status)
        }
    }
    
    public init(
        action: @escaping @MainActor @Sendable () async -> Success,
        priority: TaskPriority? = .userInitiated,
        @ViewBuilder label: @escaping () -> Label
    ) where Error == Never {
        self.init {
            Task(priority: priority) { @MainActor in
                await action()
            }
            .convertToObservableTask()
        } label: {
            label()
        }
    }
    
    public init(
        action: @escaping @MainActor @Sendable () async throws -> Success,
        priority: TaskPriority? = .userInitiated,
        @ViewBuilder label: @escaping (TaskStatus<Success, Error>) -> Label
    ) where Error == Swift.Error {
        self.init {
            Task(priority: priority) { @MainActor in
                try await action()
            }
            .convertToObservableTask()
        } label: { status in
            label(status)
        }
    }
    
    public init(
        action: @escaping @MainActor @Sendable () async throws -> Success,
        priority: TaskPriority? = .userInitiated,
        @ViewBuilder label: @escaping () -> Label
    ) where Error == Swift.Error {
        self.init {
            Task(priority: priority) { @MainActor in
                try await action()
            }
            .convertToObservableTask()
        } label: {
            label()
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension TaskButton {
    public init<P: SingleOutputPublisher>(
        action: @escaping () -> P,
        @ViewBuilder label: @escaping (TaskStatus<Success, Error>) -> Label
    ) where P.Output == Success, P.Failure == Error {
        self.init(action: { action().convertToTask() }, label: label)
    }
    
    public init<P: SingleOutputPublisher>(
        action: @escaping () -> P,
        @ViewBuilder label: () -> Label
    ) where P.Output == Success, P.Failure == Error {
        self.init(action: { action().convertToTask() }, label: label)
    }
    
    public init<P: SingleOutputPublisher>(
        action: @escaping () throws -> P,
        @ViewBuilder label: () -> Label
    ) where P.Output == Success, Error == Swift.Error {
        self.init {
            do {
                return try action().mapError({ $0 as Swift.Error }).convertToTask()
            } catch {
                return AnyTask<Success, Error>.failure(error)
            }
        } label: {
            label()
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension TaskButton where Success == Void {
    public init<P: Publisher>(
        action: @escaping () -> P,
        @ViewBuilder label: @escaping (TaskStatus<Success, Error>) -> Label
    ) where P.Output == Success, P.Failure == Error {
        self.init(action: { action().reduceAndMapTo(()).convertToTask() }, label: label)
    }
    
    public init<P: Publisher>(
        action: @escaping () -> P,
        @ViewBuilder label: () -> Label
    ) where P.Output == Success, P.Failure == Error {
        self.init(action: { action().reduceAndMapTo(()).convertToTask() }, label: label)
    }
    
    public init<P: SingleOutputPublisher>(
        action: @escaping () -> P,
        @ViewBuilder label: @escaping (TaskStatus<Success, Error>) -> Label
    ) where P.Output == Success, P.Failure == Error {
        self.init(action: { action().reduceAndMapTo(()).convertToTask() }, label: label)
    }
    
    public init<P: SingleOutputPublisher>(
        action: @escaping () -> P,
        @ViewBuilder label: () -> Label
    ) where P.Output == Success, P.Failure == Error {
        self.init(action: { action().reduceAndMapTo(()).convertToTask() }, label: label)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension TaskButton where Label == Text {
    public init(
        _ titleKey: LocalizedStringKey,
        action: @escaping () -> AnyTask<Success, Error>
    ) {
        self.init(action: action) {
            Text(titleKey)
        }
    }
    
    public init<S: StringProtocol>(
        _ title: S,
        action: @escaping () -> AnyTask<Success, Error>
    ) {
        self.init(action: action) {
            Text(title)
        }
    }
    
    public init<S: StringProtocol, P: SingleOutputPublisher>(
        _ title: S,
        action: @escaping () throws -> P
    ) where P.Output == Success, Error == Swift.Error {
        self.init(action: action) {
            Text(title)
        }
    }
    
    public init<S: StringProtocol>(
        _ title: S,
        action: @escaping @MainActor @Sendable () async -> Success
    ) where Error == Never {
        self.init(action: action) {
            Text(title)
        }
    }
    
    public init<S: StringProtocol>(
        _ title: S,
        action: @escaping @MainActor @Sendable () async throws -> Success
    ) where Error == Swift.Error {
        self.init(action: action) {
            Text(title)
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension TaskButton where Success == Void, Error == Swift.Error {
    public init(
        action: @escaping () throws -> Void,
        @ViewBuilder label: @escaping (TaskStatus<Success, Error>) -> Label
    ) {
        self.init(
            action: { () -> AnySingleOutputPublisher<Void, Error> in
                do {
                    return Just(try action())
                        .setFailureType(to: Error.self)
                        .eraseToAnySingleOutputPublisher()
                } catch {
                    return Fail(error: error)
                        .eraseToAnySingleOutputPublisher()
                }
            },
            label: label
        )
    }
    
    public init(
        action: @escaping () throws -> Void,
        @ViewBuilder label: () -> Label
    ) {
        let label = label()
        
        self.init(action: action, label: { _ in label })
    }
}
