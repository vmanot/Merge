//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publisher {
    /// Discards all errors in the stream.
    public func discardError() -> Publishers.Catch<Self, Publishers.SetFailureType<Empty<Self.Output, Never>, Never>> {
        self.catch({ _ in Empty().setFailureType(to: Never.self) })
    }
}
