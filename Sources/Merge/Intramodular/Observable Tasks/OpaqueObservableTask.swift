//
// Copyright (c) Vatsal Manot
//

import Runtime
import Swallow

public final class OpaqueObservableTask: CustomStringConvertible, ObjCObject, ObservableTask {
    public typealias StatusDescription = TaskStatusDescription

    public typealias Success = Any
    public typealias Error = Swift.Error
    
    public let base: any ObservableTask
    
    public var description: String {
        (base as? CustomStringConvertible)?.description ?? "(Task)"
    }
    
    public var status: TaskStatus<Success, Error> {
        base._opaque_status
    }
    
    public var objectWillChange: AnyObjectWillChangePublisher  {
        .init(from: base)
    }
    
    public var objectDidChange: AnyPublisher<TaskStatus<Success, Error>, Never>  {
        base._opaque_objectDidChange
    }

    public var statusDescription: StatusDescription {
        base.statusDescription
    }
        
    fileprivate init<T: ObservableTask>(erasing base: T) {
        if base is OpaqueObservableTask {
            assertionFailure()
        }
        
        self.base = base
    }
    
    @available(*, deprecated, renamed: "OpaqueObservableTask.init(erasing:)")
    public convenience init<T: ObservableTask>(_ base: T) {
        self.init(erasing: base)
    }
    
    public func start() {
        base.start()
    }
    
    public func cancel() {
        base.cancel()
    }
}

private var _ObservableTask__opaqueRepresentationKey: UInt8 = 0

extension ObservableTask {
    var _opaqueRepresentation: OpaqueObservableTask? {
        get {
            objc_getAssociatedObject(self, &_ObservableTask__opaqueRepresentationKey) as? OpaqueObservableTask
        }  set {
            objc_setAssociatedObject(self, &_ObservableTask__opaqueRepresentationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func eraseToOpaqueObservableTask() -> OpaqueObservableTask {
        _opaqueRepresentation.unwrapOrInitializeInPlace {
            OpaqueObservableTask(erasing: self)
        }
    }
}

// MARK: - Conformances

extension OpaqueObservableTask {
    public struct ID: Hashable, @unchecked Sendable {
        private let base: AnyHashable
        
        fileprivate init(base: AnyHashable) {
            self.base = base
        }
    }
    
    public var id: ID {
        .init(base: base.id.eraseToAnyHashable())
    }
}

extension OpaqueObservableTask: Equatable {
    public static func == (lhs: OpaqueObservableTask, rhs: OpaqueObservableTask) -> Bool {
        lhs.base === rhs.base
    }
}

// MARK: - Auxiliary

extension ObservableTask {
    fileprivate var _opaque_status: TaskStatus<Any, Swift.Error> {
        status.map({ $0 as Any }).mapError({ $0 as Swift.Error })
    }
            
    fileprivate var _opaque_objectDidChange: AnyPublisher<TaskStatus<Any, Swift.Error>, Never> {
        objectDidChange
            .map({ $0.map({ $0 as Any }).mapError({ $0 as Swift.Error }) })
            .eraseToAnyPublisher()
    }
}
