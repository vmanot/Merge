//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swift

/// A base class to subclass when building observable tasks.
open class ObservableTaskBase<Success, Error: Swift.Error>: ObservableTask {
    public typealias Status = ObservableTaskStatus<Success, Error>
    
    let statusValueSubject = CurrentValueSubject<Status, Never>(.idle)
    
    public var objectWillChange: AnyPublisher<Status, Never> {
        statusValueSubject.receiveOnMainThread().eraseToAnyPublisher()
    }
    
    public var objectDidChange: AnyPublisher<Status, Never> {
        statusValueSubject.eraseToAnyPublisher()
    }
    
    public var status: Status {
        statusValueSubject.value
    }
    
    public init() {
        
    }
    
    public func start() {
        
    }
    
    public func cancel() {
        
    }
}
