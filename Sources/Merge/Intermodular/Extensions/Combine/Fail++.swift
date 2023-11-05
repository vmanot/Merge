//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Fail where Output == Any, Failure == Error {
    public init(error: Failure) {
        self.init(outputType: Any.self, failure: error)
    }
}
