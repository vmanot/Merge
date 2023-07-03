//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public final class OpaqueObservableTask: CustomStringConvertible, ObservableTask {
    public typealias StatusDescription = TaskStatusDescription

    public typealias Success = Any
    public typealias Error = Swift.Error
    
    private let base: any ObservableTask
    
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

    public var id: some Hashable {
        base.id.eraseToAnyHashable()
    }
    
    public var statusDescription: StatusDescription {
        base.statusDescription
    }
        
    public init<T: ObservableTask>(erasing base: T) {
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

extension ObservableTask {
    public func eraseToOpaqueObservableTask() -> OpaqueObservableTask {
        .init(erasing: self)
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
