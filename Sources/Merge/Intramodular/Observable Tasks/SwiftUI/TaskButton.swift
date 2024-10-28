//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow
import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
/// An button that represents a `Task`.
public struct TaskButton<Success, Error: Swift.Error, Label: View>: View {
    @Environment(\._taskButtonStyle) package var taskButtonStyle
    @Environment(\.cancellables) package var cancellables
    @Environment(\.isEnabled) package var isEnabled
    @Environment(\.taskInterruptible) package var taskInterruptible
    @Environment(\.taskRestartable) package var taskRestartable
    
    package let action: () -> AnyTask<Success, Error>
    package let label: (ObservableTaskStatus<Success, Error>) -> Label
    package var existingTask: (any ObservableTask<Success, Error>)?
    
    @State package var lastTask: AnyTask<Success, Error>?
    
    package final class _CurrentTaskBox: ObservableObject {
        private let objectWillChangeRelay = ObjectWillChangePublisherRelay()
        
        var wrappedValue: AnyTask<Success, Error>? {
            didSet {
                objectWillChangeRelay.source = wrappedValue
            }
        }
        
        init() {
            objectWillChangeRelay._allowPublishingChangesFromBackgroundThreads = true
            objectWillChangeRelay.destination = self
        }
    }
    
    @StateObject package var currentTaskBox = _CurrentTaskBox()
    @State package var taskRenewalSubscription: AnyCancellable?
    @State package var wantsToDisplayLastTaskStatus: Bool = false
    
    public var currentTask: AnyTask<Success, Error>? {
        get {
            currentTaskBox.wrappedValue
        } nonmutating set {
            currentTaskBox.wrappedValue = newValue
        }
    }
    
    private var animation: MaybeKnown<Animation?> = .known(.default)
    
    private var task: AnyTask<Success, Error>? {
        if let currentTask = currentTask {
            return currentTask
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
        Group {
            _button
        }
        .disabled(isDisabled)
        ._modify(if: animation == .known) {
            $0.animation(animation.knownValue ?? nil, value: displayTaskStatus)
        }
        .onChange(of: task) { task in
            setCurrentTask(task)
        }
    }
        
    @ViewBuilder
    private var _button: some View {
        if let taskButtonStyle {
            if type(of: taskButtonStyle)._overridesButtonStyle {
                Button(action: trigger) {
                    label(task?.status ?? .idle)
                }
                .buttonStyle { configuration in
                    taskButtonStyle.makeBody(
                        configuration: TaskButtonConfiguration(
                            label: _buttonLabel,
                            isPressed: configuration.isPressed,
                            isInterruptible: taskInterruptible,
                            isRestartable: taskRestartable,
                            status: displayTaskStatus
                        )
                    )
                }
            } else {
                Button(action: trigger) {
                    AnyView(
                        taskButtonStyle.makeBody(
                            configuration: TaskButtonConfiguration(
                                label: _buttonLabel,
                                isPressed: nil,
                                isInterruptible: taskInterruptible,
                                isRestartable: taskRestartable,
                                status: displayTaskStatus
                            )
                        )
                    )
                }
            }
        } else {
            Button(action: trigger) {
                label(task?.status ?? .idle)
            }
        }
    }
    
    private var _buttonLabel: AnyView {
        AnyView(label(task?.status ?? .idle))
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
    
    @MainActor
    private func setCurrentTask(_ task: AnyTask<Success, Error>?) {
        guard task != currentTask else {
            return
        }
        
        if let task {
            lastTask = currentTask
            currentTask = task
            
            task.objectDidChange.sink(in: cancellables) { status in
                if case let .error(error) = status {
                    runtimeIssue(error)
                    
                    // handleLocalizedError(error as? LocalizedError ?? GenericTaskButtonError(base: error))
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

// MARK: - Supplementary

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension TaskButton {
    public func animation(
        _ animation: Animation?
    ) -> Self {
        var result = self
        
        result.animation = .known(animation)
        
        return result
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func _existingTask(
        _ task: (any ObservableTask<Success, Error>)?
    ) -> Self {
        var result = self
        
        result.existingTask = task
        
        return result
    }
}

// MARK: - Conformances

// FIXME: SwiftUIX dependency
/*extension TaskButton: ActionLabelView where Error == Swift.Error, Success == Void {
 public init(action: Action, label: () -> Label) {
 self.init(action: action.perform, label: label)
 }
 }*/

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

// MARK: - Internal

extension View {
    @ViewBuilder
    fileprivate func _modify<T: View>(
        @ViewBuilder transform: (Self) -> T
    ) -> some View {
        transform(self)
    }
    
    @ViewBuilder
    fileprivate func _modify<T: View>(
        if predicate: Bool,
        @ViewBuilder transform: (Self) -> T
    ) -> some View {
        if predicate {
            transform(self)
        } else {
            self
        }
    }
}

/// A type-erased wrapper for `ButtonStyle.`
fileprivate struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView
    
    fileprivate init(
        makeBody: @escaping (Configuration) -> any View
    ) {
        self._makeBody = { AnyView(makeBody($0)) }
    }
    
    fileprivate func makeBody(configuration: Configuration) -> some View {
        self._makeBody(configuration)
    }
}

extension View {
    @ViewBuilder
    fileprivate func buttonStyle(
        @ViewBuilder makeBody: @escaping (AnyButtonStyle.Configuration) -> any View
    ) -> some View {
        buttonStyle(AnyButtonStyle(makeBody: makeBody))
    }
}
