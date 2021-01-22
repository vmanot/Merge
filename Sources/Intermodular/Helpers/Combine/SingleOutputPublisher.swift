//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public protocol SingleOutputPublisher: Publisher {
    
}

// MARK: - Protocol Conformances -

extension Deferred: SingleOutputPublisher where DeferredPublisher: SingleOutputPublisher {
    
}

extension Future: SingleOutputPublisher {
    
}

extension Publishers.Autoconnect: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Catch: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Decode: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Encode: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.First: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Last: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Map: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}
