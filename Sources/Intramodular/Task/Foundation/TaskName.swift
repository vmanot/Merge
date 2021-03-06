//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swift
import SwiftUIX

public struct TaskName: Hashable {
    private let base: AnyHashable
    
    public init<H: Hashable>(_ base: H) {
        if let base = base as? TaskName {
            self = base
        } else {
            self.base = .init(base)
        }
    }
    
    public init() {
        self.init(UUID())
    }
    
    public func _cast<T>(to type: T.Type) -> T? {
        base.base as? T
    }
}

// MARK: - Auxiliary Implementation -

extension EnvironmentValues {
    public var taskName: TaskName? {
        get {
            self[DefaultEnvironmentKey<TaskName>]
        } set {
            self[DefaultEnvironmentKey<TaskName>] = newValue
        }
    }
}

// MARK: - API -

extension View {
    public func taskName(_ name: TaskName) -> some View {
        environment(\.taskName, name)
    }
    
    public func taskName<H: Hashable>(_ name: H) -> some View {
        taskName(.init(name))
    }
}
