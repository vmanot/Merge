//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public protocol _opaque_ObservableObject {
    var _opaque_objectWillChange: AnyObjectWillChangePublisher { get }
    
    func _opaque_objectWillChange_send() throws
}

// MARK: - Implementation

extension ObservableObject {
    public var _opaque_objectWillChange: AnyObjectWillChangePublisher {
        AnyObjectWillChangePublisher(from: self)
    }
}

extension _opaque_ObservableObject where Self: ObservableObject {
    public func _opaque_objectWillChange_send() throws {
        try cast(objectWillChange, to: _opaque_VoidSender.self).send()
    }
}

// MARK: - Conformances

#if canImport(CoreData)

import CoreData

extension NSManagedObject: _opaque_ObservableObject {
    
}

#endif
