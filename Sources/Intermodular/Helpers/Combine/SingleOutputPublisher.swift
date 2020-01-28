//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public protocol SingleOutputPublisher: Publisher {

}

// MARK: - Protocol Implementations -

extension Future: SingleOutputPublisher {

}
