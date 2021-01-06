//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import SwiftUI

public protocol _opaque_TaskButtonStyle {
    func _opaque_makeBody(configuration: TaskButtonConfiguration) -> AnyView
    
    func receive(status: TaskButtonStatus)
}

public protocol TaskButtonStyle: _opaque_TaskButtonStyle {
    associatedtype Body: View
    
    typealias Configuration = TaskButtonConfiguration
    
    func makeBody(configuration: TaskButtonConfiguration) -> Body
    func receive(status: TaskButtonStatus)
}

extension TaskButtonStyle {
    @inlinable
    public func receive(status: TaskButtonStatus) {
        
    }
}

// MARK: - Implementation -

extension _opaque_TaskButtonStyle where Self: TaskButtonStyle {
    public func _opaque_makeBody(configuration: TaskButtonConfiguration) -> AnyView {
        .init(makeBody(configuration: configuration))
    }
}

// MARK: - Auxiliary Implementation -

fileprivate struct TaskButtonStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: _opaque_TaskButtonStyle = DefaultTaskButtonStyle()
}

extension EnvironmentValues {
    @usableFromInline
    var buttonStyle: _opaque_TaskButtonStyle {
        get {
            self[TaskButtonStyleEnvironmentKey]
        } set {
            self[TaskButtonStyleEnvironmentKey] = newValue
        }
    }
}

// MARK: - Conformances -

public struct DefaultTaskButtonStyle: TaskButtonStyle {
    @inlinable
    public init() {
        
    }
    
    @inlinable
    public func makeBody(configuration: TaskButtonConfiguration) -> some View {
        return configuration.label
    }
}

// MARK: - API -

extension View {
    @inlinable
    public func buttonStyle<Style: TaskButtonStyle>(_ style: Style) -> some View {
        environment(\.buttonStyle, style)
    }
}
