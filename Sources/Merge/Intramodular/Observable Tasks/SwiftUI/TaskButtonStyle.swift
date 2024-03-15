//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

public protocol TaskButtonStyle: DynamicProperty {
    associatedtype Body: View
    
    typealias Configuration = TaskButtonConfiguration
    
    func makeBody(configuration: TaskButtonConfiguration) -> Body
}

// MARK: - Implementation

// MARK: - Auxiliary

fileprivate struct TaskButtonStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: (any TaskButtonStyle)? = nil
}

extension EnvironmentValues {
    @usableFromInline
    var _taskButtonStyle: (any TaskButtonStyle)? {
        get {
            self[TaskButtonStyleEnvironmentKey.self]
        } set {
            self[TaskButtonStyleEnvironmentKey.self] = newValue
        }
    }
}

// MARK: - Conformances

@frozen
public struct DefaultTaskButtonStyle: TaskButtonStyle {
    @inlinable
    public init() {
        
    }
    
    @inlinable
    public func makeBody(configuration: TaskButtonConfiguration) -> some View {
        configuration.label
    }
}

#if os(iOS) || os(macOS) || os(tvOS) || targetEnvironment(macCatalyst)

@available(iOS 15.0, macOS 14.0, tvOS 15.0, watchOS 8.0, *)
@frozen
public struct ActivityIndicatorTaskButtonStyle: TaskButtonStyle {
    @inlinable
    public init() {
        
    }
    
    @inlinable
    public func makeBody(configuration: TaskButtonConfiguration) -> some View {
        Group {
            if configuration.status == .active {
                #if os(macOS)
                    ProgressView()
                        .controlSize(.small)
                #else
                    ProgressView()
                        .controlSize(.regular)
                #endif
            } else if configuration.status == .failure {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .imageScale(.small)
            } else {
                configuration.label
            }
        }
    }
}

#endif

// MARK: - API

extension View {
    /// Sets the style for task buttons within this view to a task button style with a custom appearance and custom interaction behavior.
    public func taskButtonStyle<Style: TaskButtonStyle>(_ style: Style) -> some View {
        modifier(_AttachTaskButtonStyle(style: style))
    }
}

// MARK: - Auxiliary

private struct _AttachTaskButtonStyle<Style: TaskButtonStyle>: ViewModifier {
    let style: Style
    
    func body(content: Content) -> some View {
        content.environment(\._taskButtonStyle, style)
    }
}
