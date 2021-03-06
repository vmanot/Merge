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

extension Fail: SingleOutputPublisher {
    
}

extension Future: SingleOutputPublisher {
    
}

extension Just: SingleOutputPublisher {
    
}

extension Publishers.Autoconnect: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Catch: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Decode: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Encode: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.First: SingleOutputPublisher {
    
}

extension Publishers.Last: SingleOutputPublisher {
    
}

extension Publishers.Map: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Print: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.ReceiveOn: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Result.Publisher: SingleOutputPublisher {
    
}
