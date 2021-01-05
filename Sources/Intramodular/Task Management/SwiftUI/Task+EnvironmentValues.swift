//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUIX

@usableFromInline
struct TaskDisabledEnvironmentKey: EnvironmentKey {
    @usableFromInline
    static let defaultValue: Bool = false
}

@usableFromInline
struct TaskInterruptibleEnvironmentKey: EnvironmentKey {
    @usableFromInline
    static let defaultValue: Bool = true
}

@usableFromInline
struct TaskRestartableEnvironmentKey: EnvironmentKey {
    @usableFromInline
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    @usableFromInline
    var taskDisabled: Bool {
        get {
            self[TaskDisabledEnvironmentKey]
        } set {
            self[TaskDisabledEnvironmentKey] = newValue
        }
    }
    
    @usableFromInline
    var taskInterruptible: Bool {
        get {
            self[TaskInterruptibleEnvironmentKey]
        } set {
            self[TaskInterruptibleEnvironmentKey] = newValue
        }
    }
    
    @usableFromInline
    var taskRestartable: Bool {
        get {
            self[TaskRestartableEnvironmentKey]
        } set {
            self[TaskRestartableEnvironmentKey] = newValue
        }
    }
}

// MARK: - API -

extension View {
    @inlinable
    public func taskDisabled(_ disabled: Bool) -> some View {
        environment(\.taskDisabled, disabled)
    }
    
    @inlinable
    public func taskInterruptible(_ disabled: Bool) -> some View {
        environment(\.taskInterruptible, disabled)
    }
    
    @inlinable
    public func taskRestartable(_ disabled: Bool) -> some View {
        environment(\.taskRestartable, disabled)
    }
}
