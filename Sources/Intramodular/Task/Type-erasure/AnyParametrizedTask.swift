//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swift

open class AnyParametrizedTask<Input, Success, Error: Swift.Error>: Task {
    public typealias Status = TaskStatus<Success, Error>
    
    public let base: _opaque_Task
    
    private let getStatusImpl: () -> Status
    private let getObjectWillChangeImpl: () -> AnyPublisher<Status, Never>
    private let receiveInputImpl: (Input) throws -> ()
    
    public var cancellables: Cancellables {
        base.cancellables
    }
    
    public var name: TaskName {
        base.name
    }
    
    public var status: Status {
        getStatusImpl()
    }
    
    public var progress: Progress {
        base.progress
    }
    
    public var objectWillChange: AnyPublisher<Status, Never> {
        getObjectWillChangeImpl()
    }
    
    public init<T: ParametrizedTask>(_ base: T) where T.Input == Input, T.Success == Success, T.Error == Error {
        self.base = base
        
        self.getStatusImpl = { base.status }
        self.getObjectWillChangeImpl = { base.objectWillChange.eraseToAnyPublisher() }
        self.receiveInputImpl = base.receive
    }
    
    public func receive(_ input: Input) throws {
        try receiveInputImpl(input)
    }
    
    public func start() {
        base.start()
    }
    
    public func cancel() {
        base.cancel()
    }
}

// MARK: - API -

extension ParametrizedTask {
    public func eraseToAnyTask() -> AnyParametrizedTask<Input, Success, Error> {
        .init(self)
    }
}
