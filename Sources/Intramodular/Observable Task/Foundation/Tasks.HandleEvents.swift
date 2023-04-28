//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

extension Tasks {
    public final class HandleEvents<Base: ObservableTask>: ObservableTask {
        public typealias Success = Base.Success
        public typealias Error = Base.Error
        
        private let base: Base
        
        private let receiveStart: (() -> Void)?
        private let receiveCancel: (() -> Void)?
        
        public var objectWillChange: Base.ObjectWillChangePublisher {
            base.objectWillChange
        }
        
        public var status: TaskStatus<Success, Error> {
            base.status
        }
                
        public init(
            base: Base,
            receiveStart: (() -> Void)? = nil,
            receiveCancel: (() -> Void)? = nil
        ) {
            self.base = base
            
            self.receiveStart = receiveStart
            self.receiveCancel = receiveCancel
        }
        
        public func start() {
            if status == .idle {
                receiveStart?()
            }
            
            base.start()
        }
        
        public func cancel() {
            if status != .canceled || status != .success {
                receiveCancel?()
            }
            
            base.cancel()
        }
    }
}

// MARK: - API

extension ObservableTask {
    public func handleEvents(
        receiveStart: (() -> Void)? = nil,
        receiveCancel: (() -> Void)? = nil
    ) -> Tasks.HandleEvents<Self> {
        .init(
            base: self,
            receiveStart: receiveStart,
            receiveCancel: receiveCancel
        )
    }
}
