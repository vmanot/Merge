//
// Copyright (c) Vatsal Manot
//

@_exported import Diagnostics
@_exported import Combine
@_exported import Swallow
@_exported import SwallowMacrosClient
@_exported import SwiftDI

public enum _module {
    
}

// MARK: - Deprecated

@available(*, deprecated, renamed: "ObservableTaskFailure")
public typealias TaskFailure<E: Error> = ObservableTaskFailure<E>
@available(*, deprecated, renamed: "ObservableTaskStatusType")
public typealias TaskStatusType = ObservableTaskStatusType
@available(*, deprecated, renamed: "ObservableTaskStatus")
public typealias TaskStatus<T, U: Error> = ObservableTaskStatus<T, U>
@available(*, deprecated, renamed: "ObservableTaskStatusDescription")
public typealias TaskStatusDescription = ObservableTaskStatusDescription
