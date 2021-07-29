//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swift
import SwiftUIX

public struct TaskIdentifier: Hashable {
    private let base: AnyHashable
    
    public init<H: Hashable>(_ base: H) {
        if let base = base as? TaskIdentifier {
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
    public var taskName: TaskIdentifier? {
        get {
            self[DefaultEnvironmentKey<TaskIdentifier>.self]
        } set {
            self[DefaultEnvironmentKey<TaskIdentifier>.self] = newValue
        }
    }
}

// MARK: - API -

extension View {
    public func taskName(_ name: TaskIdentifier) -> some View {
        environment(\.taskName, name)
    }
    
    public func taskName<H: Hashable>(_ name: H) -> some View {
        taskName(.init(name))
    }
}
