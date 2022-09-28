//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension ObservableObject {
    /// Wrap this observable object's `objectWillChange` publisher with a type-eraser.
    public func eraseObjectWillChangePublisher() -> AnyObjectWillChangePublisher {
        .init(from: self)
    }
}
