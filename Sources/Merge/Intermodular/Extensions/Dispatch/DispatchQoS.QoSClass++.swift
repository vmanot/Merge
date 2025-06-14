//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Foundation
import Swallow

extension DispatchQoS.QoSClass {
    public static var current: Self {
        DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified
    }
    
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
