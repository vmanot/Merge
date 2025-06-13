//
// Copyright (c) Vatsal Manot
//

#if !canImport(PermissionKit)

import Darwin
import Swallow

public enum DarwinAtomicOperationMemoryOrder: Hashable {
    case relaxed
    case consume
    case acquire
    case release
    case acquireRelease
    case sequentiallyConsistent
}

// MARK: - Conformances

extension DarwinAtomicOperationMemoryOrder: Codable {
    public init(from decoder: Decoder) throws {
        self.init(rawValue: try RawValue(from: decoder))
    }
    
    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}

extension DarwinAtomicOperationMemoryOrder: RawRepresentable {
    public typealias RawValue = memory_order
    
    public var rawValue: memory_order {
        switch self {
            case .relaxed:
                return memory_order_relaxed
            case .consume:
                return memory_order_consume
            case .acquire:
                return memory_order_acquire
            case .release:
                return memory_order_release
            case .acquireRelease:
                return memory_order_acq_rel
            case .sequentiallyConsistent:
                return memory_order_seq_cst
        }
    }
    
    @inlinable
    public init(rawValue: memory_order) {
        switch rawValue {
            case memory_order_relaxed:
                self = .relaxed
            case memory_order_consume:
                self = .consume
            case memory_order_acquire:
                self = .acquire
            case memory_order_release:
                self = .release
            case memory_order_acq_rel:
                self = .acquireRelease
            case memory_order_seq_cst:
                self = .sequentiallyConsistent
            default:
                self = Never.materialize(reason: .impossible)
        }
    }
}

// MARK: - Ancillary Conformances -

extension memory_order: Codable {
    public init(from decoder: Decoder) throws {
        self.init(rawValue: try UInt32(from: decoder))
    }
    
    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}

#endif
