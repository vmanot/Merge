//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUIX

public struct TaskButtonConfiguration {
    public let label: AnyView
    
    public let isDisabled: Bool
    public let isInterruptible: Bool
    public let isRestartable: Bool
    
    public let status: TaskStatusDescription
    public let lastStatus: TaskStatusDescription?
}
