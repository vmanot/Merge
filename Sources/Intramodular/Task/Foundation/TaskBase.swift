//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

open class TaskBase<Success, Error: Swift.Error>: Task {
    public typealias Status = TaskStatus<Success, Error>
    
    public let cancellables = Cancellables()
    
    @usableFromInline
    internal let statusValueSubject = CurrentValueSubject<Status, Never>(.idle)
    
    public var taskIdentifier: TaskIdentifier = .init() {
        willSet {
            guard status != .active else {
                fatalError("Cannot change the name of an active task.")
            }
        }
    }
    
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
