//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

open class TaskBase<Success, Error: Swift.Error>: ObservableTask {
    public typealias Status = TaskStatus<Success, Error>
    
    @usableFromInline
    internal let statusValueSubject = CurrentValueSubject<Status, Never>(.idle)
        
    public var objectWillChange: AnyPublisher<Status, Never> {
        statusValueSubject.eraseToAnyPublisher()
    }
    
    public var status: Status {
        statusValueSubject.value
    }
    
    public let progress = Progress()
    
    public init() {
        
    }
    
    public func start() {
        
    }
    
    public func cancel() {
        
    }
}
