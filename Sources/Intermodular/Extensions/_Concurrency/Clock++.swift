//
// Copyright (c) Vatsal Manot
//

import Swift

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension Clock {
    @_disfavoredOverload
    public func measure<T>(
        _ work: () throws -> T
    ) rethrows -> (result: T, duration: Duration) {
        var result: T!
        
        let duration = try measure {
            result = try work()
        }
        
        return (result, duration)
    }
    
    @_disfavoredOverload
    public func measure<T>(
        _ work: () async throws -> T
    ) async rethrows -> (result: T, duration: Duration) {
        var result: T!
        
        let duration = try await measure {
            result = try await work()
        }
        
        return (result, duration)
    }
}
