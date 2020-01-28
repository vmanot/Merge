//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

extension Cancellables {
    public final class Concatenate<T: Cancellable, U: Cancellable>: Cancellable {
        public let prefix: T
        public let suffix: U
        
        public init(prefix: T, suffix: U) {
            self.prefix = prefix
            self.suffix = suffix
        }
        
        public func cancel() {
            prefix.cancel()
            suffix.cancel()
        }
    }
}

extension Cancellable {
    public func concatenate<T: Cancellable>(with other: T) -> Cancellables.Concatenate<Self, T> {
        .init(prefix: self, suffix: other)
    }
}
