//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

public protocol TaskButtonStyle: DynamicProperty {
    associatedtype Body: View
    
    typealias Configuration = TaskButtonConfiguration
    
    static var _overridesButtonStyle: Bool { get }
    
    func makeBody(configuration: TaskButtonConfiguration) -> Body
}

// MARK: - Auxiliary

fileprivate struct TaskButtonStyleEnvironmentKey: EnvironmentKey {
    static var defaultValue: (any TaskButtonStyle)? = {
        if #available(iOS 15.0, macOS 14.0, tvOS 15.0, watchOS 8.0, *) {
            return ActivityIndicatorTaskButtonStyle()
        } else {
            return nil
        }
    }()
}

extension EnvironmentValues {
    @usableFromInline
    var _taskButtonStyle: (any TaskButtonStyle)? {
        get {
            self[TaskButtonStyleEnvironmentKey.self]
        }
        set {
            self[TaskButtonStyleEnvironmentKey.self] = newValue
        }
    }
}

// MARK: - Conformances

@frozen
public struct DefaultTaskButtonStyle: TaskButtonStyle {
    public static var _overridesButtonStyle: Bool {
        false
    }
    
    @inlinable
    public init() {
        
    }
    
    @inlinable
    public func makeBody(configuration: TaskButtonConfiguration) -> some View {
        configuration.label
    }
}

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS) || os(watchOS) || targetEnvironment(macCatalyst)

@available(iOS 15.0, macOS 14.0, tvOS 15.0, watchOS 8.0, *)
@frozen
public struct ActivityIndicatorTaskButtonStyle: TaskButtonStyle {
    public static var _overridesButtonStyle: Bool {
        false
    }
    
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
                #elseif os(iOS) || os(visionOS)
                ProgressView()
                    .controlSize(.regular)
                #else
                ProgressView()
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
