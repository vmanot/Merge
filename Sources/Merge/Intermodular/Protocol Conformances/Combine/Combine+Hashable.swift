//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension Published: Swift.Equatable where Value: Swift.Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._wrappedValue == rhs._wrappedValue
    }
}

extension Published: Swift.Hashable where Value: Swift.Hashable {
    public func hash(into hasher: inout Hasher) {
        _wrappedValue.hash(into: &hasher)
    }
}
