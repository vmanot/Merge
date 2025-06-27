//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation

public final class EmptyObservableTask<Success, Error: Swift.Error>: ObservableTask {
    public var status: ObservableTaskStatus<Success, Error> {
        .idle
    }
    
    public var objectWillChange: AnyPublisher<ObservableTaskStatus<Success, Error>, Never> {
        Empty().eraseToAnyPublisher()
    }
    
    public var objectDidChange: AnyPublisher<ObservableTaskStatus<Success, Error>, Never> {
        Empty().eraseToAnyPublisher()
    }
    
    public init() {
        
    }
    
    public init() where Success == Void, Error == Never {
        
    }
    
    public func start() {
        
    }
    
    public func cancel() {
        
    }
}
