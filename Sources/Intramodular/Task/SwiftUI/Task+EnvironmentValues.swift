//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import SwiftUI

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
            self[TaskDisabledEnvironmentKey.self]
        } set {
            self[TaskDisabledEnvironmentKey.self] = newValue
        }
    }
    
    @usableFromInline
    var taskInterruptible: Bool {
        get {
            self[TaskInterruptibleEnvironmentKey.self]
        } set {
            self[TaskInterruptibleEnvironmentKey.self] = newValue
        }
    }
    
    @usableFromInline
    var taskRestartable: Bool {
        get {
            self[TaskRestartableEnvironmentKey.self]
        } set {
            self[TaskRestartableEnvironmentKey.self] = newValue
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
