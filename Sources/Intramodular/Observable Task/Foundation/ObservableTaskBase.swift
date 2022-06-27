//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swift

/// A base class to subclass when building observable tasks.
open class ObservableTaskBase<Success, Error: Swift.Error>: ObservableTask {
    public typealias Status = TaskStatus<Success, Error>
    
    let statusValueSubject = CurrentValueSubject<Status, Never>(.idle)
    
    public var objectWillChange: AnyPublisher<Status, Never> {
        statusValueSubject.receiveOnMainThread().eraseToAnyPublisher()
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
