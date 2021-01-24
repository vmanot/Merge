//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

open class TaskBase<Success, Error: Swift.Error>: TaskProtocol {
    public typealias Status = TaskStatus<Success, Error>
    
    public let cancellables = Cancellables()
    
    @Published public private(set) var combineIdentifier = CombineIdentifier()
    
    @usableFromInline
    internal let statusValueSubject = CurrentValueSubject<Status, Never>(.idle)
    
    public var name: TaskName = .init() {
        willSet {
            guard status != .active else {
                fatalError("Cannot change the name of an active task.")
            }
        }
        
        didSet {
            combineIdentifier = .init()
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
