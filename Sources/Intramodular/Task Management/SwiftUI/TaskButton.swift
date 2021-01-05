//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUIX

/// An button that represents a `Task`.
public struct TaskButton<Success, Error: Swift.Error, Label: View>: View {
    private let action: () -> AnyTask<Success, Error>?
    private let label: (TaskStatus<Success, Error>) -> Label
    
    @OptionalEnvironmentObject var taskPipeline: TaskPipeline?
    @OptionalObservedObject var currentTask: AnyTask<Success, Error>?
    
    @Environment(\.buttonStyle) var buttonStyle
    @Environment(\.cancellables) var cancellables
    @Environment(\.errorContext) var errorContext
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.taskName) var taskName
    @Environment(\.taskDisabled) var taskDisabled
    @Environment(\.taskInterruptible) var taskInterruptible
    @Environment(\.taskRestartable) var taskRestartable
    
    public var task: AnyTask<Success, Error>? {
        if let currentTask = currentTask {
            return currentTask
        } else if let taskName = taskName, let task = taskPipeline?[taskName] as? AnyTask<Success, Error> {
            return task
        } else {
            return nil
        }
    }
    
    public var taskStatusDescription: TaskStatusDescription {
        return task?.statusDescription
            ?? taskName.flatMap({ taskPipeline?.lastStatus(for: $0) })
            ?? .idle
    }
    
    public var lastTaskStatusDescription: TaskStatusDescription? {
        taskName.flatMap({ taskPipeline?.lastStatus(for: $0) })
    }
    
    @State var taskRenewalSubscription: AnyCancellable?
    
    public var body: some View {
        Button(action: trigger) {
            buttonStyle._opaque_makeBody(
                configuration: TaskButtonConfiguration(
                    label: label(task?.status ?? .idle).eraseToAnyView(),
                    isDisabled: taskDisabled,
                    isInterruptible: taskInterruptible,
                    isRestartable: taskRestartable,
                    status: taskStatusDescription,
                    lastStatus: lastTaskStatusDescription
                )
            )
        }
        .disabled(!isEnabled || taskDisabled)
    }
    
    private func trigger() {
        if !taskRestartable && currentTask != nil {
            return
        }
        
        acquireTaskIfNecessary()
    }
    
    private func subscribe(to task: AnyTask<Success, Error>) {
        task.objectWillChange.sink(
            in: taskPipeline?.cancellables ?? cancellables
        ) { [weak errorContext] status in
            self.buttonStyle.receive(status: .init(description: TaskStatusDescription(status)))
            
            if case let .error(error) = status {
                errorContext?.push(error)
            }
        }
        
        currentTask = task
        
        if task.status == .idle {
            task.start()
        }
    }
    
    private func acquireTaskIfNecessary() {
        if taskInterruptible {
            if let task = action() {
                return subscribe(to: task)
            }
        }
        
        if let taskName = taskName, let taskPipeline = taskPipeline, let task = taskPipeline[taskName] as? AnyTask<Success, Error> {
            currentTask = task
        } else {
            if let task = action() {
                subscribe(to: task)
            } else {
                currentTask = nil
            }
        }
    }
}

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
    
    public init<P: Publisher>(
        action: @escaping () -> P,
        @ViewBuilder label: @escaping (TaskStatus<Success, Error>) -> Label
    ) where P.Output == Success, P.Failure == Error {
        self.init(action: { action().convertToTask() }, label: label)
    }
    
    public init<P: Publisher>(
        action: @escaping () -> P,
        @ViewBuilder label: () -> Label
    ) where P.Output == Success, P.Failure == Error {
        self.init(action: { action().convertToTask() }, label: label)
    }
}

extension TaskButton where Success == Void, Error == Swift.Error {
    public init(
        action: @escaping () throws -> Void,
        @ViewBuilder label: @escaping (TaskStatus<Success, Error>) -> Label
    ) {
        self.init(
            action: { () -> AnyPublisher<Void, Error> in
                do {
                    return Just(try action())
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } catch {
                    return Fail(error: error)
                        .eraseToAnyPublisher()
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
