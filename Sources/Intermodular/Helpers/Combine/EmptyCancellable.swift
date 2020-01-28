//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

public final class EmptyCancellable: Cancellable {
    public init() {
        
    }
    
    public func cancel() {
        
    }
}

// MARK: - API -

extension AnyCancellable {
    public static func empty() -> Self {
        .init(EmptyCancellable())
    }
}
