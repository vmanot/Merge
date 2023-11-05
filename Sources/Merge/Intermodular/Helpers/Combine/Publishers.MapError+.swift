//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publisher {
    public func eraseError() -> Publishers.MapError<Self, Error> {
        mapError({ $0 as Error })
    }
}
