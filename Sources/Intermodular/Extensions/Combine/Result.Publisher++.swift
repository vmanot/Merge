//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Result.Publisher where Failure == Swift.Error {
    public init(_ output: () throws -> Success) {
        self = Result(catching: output).publisher
    }
}
