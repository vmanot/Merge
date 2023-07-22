//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow
import SwiftUIX

/// An button that represents a `Task`.
public struct TaskButton<Success, Error: Swift.Error, Label: View>: View {
    @Environment(\._taskButtonStyle) private var buttonStyle
    @Environment(\.cancellables) private var cancellables
    @Environment(\.customTaskIdentifier) private var customTaskIdentifier
    @Environment(\.handleLocalizedError) private var handleLocalizedError
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.taskInterruptible) private var taskInterruptible
    @Environment(\.taskRestartable) private var taskRestartable
    
    private let action: () -> AnyTask<Success, Error>
    private let label: (TaskStatus<Success, Error>) -> Label
    
    @EnvironmentObject.Optional private var _taskGraph: _ObservableTaskGraph?
    
    var existingTask: (any ObservableTask<Success, Error>)?
        
    @State private var lastTask: AnyTask<Success, Error>?
    
    @PersistentObject private var currentTask: AnyTask<Success, Error>?
    
    @State private var taskRenewalSubscription: AnyCancellable?
    @State private var wantsToDisplayLastTaskStatus: Bool = false
    
    private var animation: MaybeKnown<Animation?> = .known(.default)
    
    private var task: AnyTask<Success, Error>? {
        if let currentTask = currentTask {
            return currentTask
        } else if let customTaskIdentifier = customTaskIdentifier, let task = _taskGraph?[customTaskIdentifier: customTaskIdentifier] as? AnyTask<Success, Error> {
            return task
        } else if let existingTask {
            let task = existingTask._opaque_eraseToAnyTask() as! AnyTask<Success, Error>
            
            if lastTask == task, currentTask == nil {
                return nil
            } else {
                return task
            }
        } else {
            return nil
        }
    }
    
    private var displayTaskStatus: TaskStatusDescription {
        if let status = task?.statusDescription {
            return status
        } else if let status = customTaskIdentifier.flatMap({ _taskGraph?.lastStatus(forCustomTaskIdentifier: $0) }) {
            if status == .failure {
                return status
            } else {
                assert(status.isTerminal)
                
                return .idle
            }
        } else {
            return .idle
        }
    }
    
    private var isDisabled: Bool {
        false
            || !isEnabled
            || (currentTask?.status == .finished && !taskRestartable)
            || (currentTask?.status == .active && !taskInterruptible)
    }
        
    public var body: some View {
        Button(action: trigger) {
            label(task?.status ?? .idle)
        }
        .modify {
            if let buttonStyle {
                $0.buttonStyle { configuration in
                    buttonStyle.makeBody(
                        configuration: TaskButtonConfiguration(
                            label: configuration.label.eraseToAnyView(),
                            isPressed: configuration.isPressed,
                            isInterruptible: taskInterruptible,
                            isRestartable: taskRestartable,
                            status: displayTaskStatus
                        )
                    )
                    .eraseToAnyView()
                }
            } else {
                $0
            }
        }
        .disabled(isDisabled)
        .modify(if: animation == .known) {
            $0.animation(animation.knownValue ?? nil, value: displayTaskStatus)
        }
        .onChange(of: task) { task in
            setCurrentTask(task)
        }
    }
    
    private func trigger() {
        if currentTask != nil {
            guard taskRestartable else {
                return
            }
        }
        
        let task = action()
        
        setCurrentTask(task)

        task.start()

        wantsToDisplayLastTaskStatus = true
    }
        
    private func setCurrentTask(_ task: AnyTask<Success, Error>?) {
        guard task != currentTask else {
            return
        }
                
        if let task {
            lastTask = currentTask
            currentTask = task
            
            task.objectDidChange.sink(in: _taskGraph?.cancellables ?? cancellables) { status in
                if case let .error(error) = status {
                    runtimeIssue(error)
                    
                    handleLocalizedError(error as? LocalizedError ?? GenericTaskButtonError(base: error))
                }
                
                if status.isTerminal {
                    setCurrentTask(nil)
                }
            }
        } else {
            lastTask = currentTask
            currentTask = nil
        }
    }
}

// MARK: - Initializers

extension TaskButton {
    public init(
        action: @escaping () -> AnyTask<Success, Error>,
        @ViewBuilder label: @escaping (TaskStatus<Success, Error>) -> Label
    ) {
        self.action = { action() }
        self.label = label
    }
    
    public init(
        action: @escaping () -> AnyTask<Success, Error>,
        @ViewBuilder label: () -> Label
    ) {
        let _label = label()
        
        self.action = { action() }
        self.label = { _ in _label }
    }
}

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

// MARK: - Supplementary

extension TaskButton {
    public func animation(_ animation: Animation?) -> Self {
        then {
            $0.animation = .known(animation)
        }
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func _existingTask(_ task: (any ObservableTask<Success, Error>)?) -> Self {
        then {
            $0.existingTask = task
        }
    }
}

// MARK: - Conformances

extension TaskButton: ActionLabelView where Error == Swift.Error, Success == Void {
    public init(action: Action, label: () -> Label) {
        self.init(action: action.perform, label: label)
    }
}

// MARK: - Auxiliary

struct GenericTaskButtonError: CustomStringConvertible, LocalizedError {
    let base: Swift.Error
    
    public var description: String {
        String(describing: base)
    }
    
    public var errorDescription: String? {
        (base as? LocalizedError)?.errorDescription
    }
}

extension EnvironmentValues {
    public var customTaskIdentifier: AnyHashable? {
        get {
            self[DefaultEnvironmentKey<AnyHashable>.self]
        } set {
            self[DefaultEnvironmentKey<AnyHashable>.self] = newValue
        }
    }
}

// MARK: - API

extension View {
    public func customTaskIdentifier(_ name: AnyHashable) -> some View {
        environment(\.customTaskIdentifier, name)
    }
    
    public func customTaskIdentifier<H: Hashable>(_ name: H) -> some View {
        customTaskIdentifier(.init(name))
    }
}
