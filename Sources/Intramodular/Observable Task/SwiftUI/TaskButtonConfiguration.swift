//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import SwiftUI

public struct TaskButtonConfiguration {
    public let label: AnyView
    public let isPressed: Bool

    public let isDisabled: Bool
    public let isInterruptible: Bool
    public let isRestartable: Bool
    
    public let status: TaskStatusDescription
    public let lastStatus: TaskStatusDescription?
}
