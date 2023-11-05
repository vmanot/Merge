//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Just {
    public init(_ output: () -> Output) {
        self.init(output())
    }
}
