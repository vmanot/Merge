//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension Published: Equatable where Value: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._wrappedValue == rhs._wrappedValue
    }
}

extension Published: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        _wrappedValue.hash(into: &hasher)
    }
}
