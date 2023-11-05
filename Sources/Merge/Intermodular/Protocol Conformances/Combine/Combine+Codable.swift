//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Published: Decodable where Value: Decodable {
    public init(from decoder: Decoder) throws {
        self.init(wrappedValue: try .init(from: decoder))
    }
}

extension Published: Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        try _wrappedValue.encode(to: encoder)
    }
}
