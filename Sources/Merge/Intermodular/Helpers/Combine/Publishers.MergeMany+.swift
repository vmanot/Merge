//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Array where Element: Publisher {
    /// Creates a merge-many publisher from the array's elements.
    public var mergeManyPublisher: Publishers.MergeMany<Element> {
        .init(self)
    }
}
