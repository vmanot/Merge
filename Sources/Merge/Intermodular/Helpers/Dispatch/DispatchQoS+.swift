//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Swallow

extension DispatchQoS.QoSClass: Swift.CaseIterable {
    public static let allCases: [DispatchQoS.QoSClass] = [
        .background,
        .utility,
        .`default`,
        .userInitiated,
        .userInteractive,
        .unspecified
    ]
}

extension DispatchQoS: Swift.Comparable {
    public static func < (lhs: DispatchQoS, rhs: DispatchQoS) -> Bool {
        return lhs.qosClass < rhs.qosClass
    }
}

extension DispatchQoS.QoSClass: Swift.Comparable {
    private var sortValue: UInt32 {
        #if !os(Linux)
        return rawValue.rawValue
        #else
        switch self {
        case .background: return 0x09
        // case .maintenance: return 0x05
        case .utility: return 0x11
        case .default: return 0x15
        case .userInitiated: return 0x19
        case .userInteractive: return 0x21
        case .unspecified: return 0x00
        }
        #endif
    }

    public static func < (lhs: DispatchQoS.QoSClass, rhs: DispatchQoS.QoSClass) -> Bool {
        return lhs.sortValue < rhs.sortValue
    }
}
