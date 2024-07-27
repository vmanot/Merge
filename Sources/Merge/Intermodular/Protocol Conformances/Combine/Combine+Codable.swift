//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Combine.Published: Swift.Decodable where Value: Decodable {
    public init(from decoder: Decoder) throws {
        self.init(wrappedValue: try Value(from: decoder))
    }
}

extension Combine.Published: Swift.Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        try _wrappedValue.encode(to: encoder)
    }
}
