//
// Copyright (c) Vatsal Manot
//

import Foundation
import Combine
import Swift

extension Tasks {
    public final class Map<Upstream: TaskProtocol, Success>: TaskProtocol {
        public typealias Success = Success
        public typealias Error = Upstream.Error
        public typealias Status = TaskStatus<Success, Error>
        
        private let upstream: Upstream
        private let transform: (Upstream.Success) -> Success
        
        public var objectWillChange: AnyPublisher<Status, Never> {
            let tranform = self.transform
            
            return upstream.objectWillChange.map({ $0.map(tranform) }).eraseToAnyPublisher()
        }
        
        public init(
            upstream: Upstream,
            transform: @escaping (Upstream.Success) -> Success
        ) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public let name: TaskName = .init() // FIXME!!!
        
        public var status: TaskStatus<Success, Error> {
            upstream.status.map(transform)
        }
        
        public var progress: Progress {
            upstream.progress
        }
        
        public func start() {
            upstream.start()
        }
        
        public func pause() throws {
            try upstream.pause()
        }
        
        public func resume() throws {
            try upstream.resume()
        }
        
        public func cancel() {
            upstream.cancel()
        }
    }
}

// MARK: - API -

extension TaskProtocol {
    public func map<T>(_ transform: @escaping (Success) -> T) -> Tasks.Map<Self, T> {
        Tasks.Map(upstream: self, transform: transform)
    }
}
