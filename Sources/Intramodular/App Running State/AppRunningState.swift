//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

/// An enum that represents the running state of an iOS, macOS, tvOS or watchOS application.
public enum AppRunningState {
    case active
    case inactive
    case background
}
