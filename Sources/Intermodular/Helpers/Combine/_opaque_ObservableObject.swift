//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public protocol _opaque_ObservableObject {
    var _opaque_objectWillChange: AnyPublisher<Any, Never> { get }
    
    func _opaque_objectWillChange_send() throws
}

// MARK: - Implementation -

extension _opaque_ObservableObject where Self: ObservableObject {
    public var _opaque_objectWillChange: AnyPublisher<Any, Never> {
        objectWillChange.map({ $0 }).eraseToAnyPublisher()
    }
    
    public func _opaque_objectWillChange_send() throws {
        try cast(objectWillChange, to: _opaque_VoidSender.self).send()
    }
}

// MARK: - Conformances -

#if canImport(CoreData)

import CoreData

extension NSManagedObject: _opaque_ObservableObject {
    
}

#endif
