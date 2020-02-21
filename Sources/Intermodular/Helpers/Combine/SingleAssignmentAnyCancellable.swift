//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Combine
import Swift

open class SingleAssignmentAnyCancellable: Cancellable {
    static let cancelQueue = DispatchQueue(label:
        "com.vmanot.Merge.SingleAssignmentAnyCancellable")
    
    private var base: AnyCancellable = .empty()
    
    public init() {
        
    }
    
    public func set<C: Cancellable>(_ base: C) {
        self.base = .init(base)
    }
    
    public func cancel() {
        Self.cancelQueue.async {
            self.base = .empty()
        }
    }
}
