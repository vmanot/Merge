//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension ObservableObject {
    /// Wrap this observable object's `objectWillChange` publisher with a type-eraser.
    public func eraseObjectWillChangePublisher() -> AnyObjectWillChangePublisher {
        .init(from: self)
    }

    public func _opaque_publishToObjectWillChange() throws {
        try cast(objectWillChange, to: (any _opaque_VoidSender).self).send()
    }
}
