//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Array where Element: Publisher {
    public var mergeManyPublisher: Publishers.MergeMany<Element> {
        .init(self)
    }
}
