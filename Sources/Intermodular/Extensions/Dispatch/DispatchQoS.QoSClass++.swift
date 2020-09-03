//
// Copyright (c) Vatsal Manot
//

import Foundation
import Dispatch
import Swallow

extension DispatchQoS.QoSClass {
    public init(qos: QualityOfService) {
        switch qos {
            case .userInteractive:
                self = .userInteractive
            case .userInitiated:
                self = .userInitiated
            case .utility:
                self = .utility
            case .background:
                self = .background
            case .default:
                self = .default
            @unknown default:
                self = .default
        }
    }
}
