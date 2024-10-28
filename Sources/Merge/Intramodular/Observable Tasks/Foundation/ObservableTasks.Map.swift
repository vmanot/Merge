//
// Copyright (c) Vatsal Manot
//

import Foundation
import Combine
import Swift

extension ObservableTasks {
    public final class Map<Upstream: ObservableTask, Success>: ObservableTask {
        public typealias Success = Success
        public typealias Error = Upstream.Error
        public typealias Status = ObservableTaskStatus<Success, Error>
        
        private let upstream: Upstream
        private let transform: (Upstream.Success) -> Success
        
        public var objectWillChange: AnyObjectWillChangePublisher {
            .init(from: upstream)
        }
        
        public var objectDidChange: AnyPublisher<Status, Never> {
            let transform = self.transform
            
            return upstream.objectDidChange.map({ $0.map(transform) }).eraseToAnyPublisher()
        }
        
        public init(
            upstream: Upstream,
            transform: @escaping (Upstream.Success) -> Success
        ) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public var status: ObservableTaskStatus<Success, Error> {
            upstream.status.map(transform)
        }
                
        public func start() {
            upstream.start()
        }
        
        public func cancel() {
            upstream.cancel()
        }
        
    }
}

// MARK: - API

extension ObservableTask {
    public func map<T>(
        _ transform: @escaping (Success) -> T
    ) -> ObservableTasks.Map<Self, T> {
        ObservableTasks.Map(upstream: self, transform: transform)
    }
}
