//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Foundation
@_spi(Internal) import Swallow
import System

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    public func start() async throws {
        let _: Void = run()
        
        try await processDidStart.enter()
    }
    
    public func start(
        completion: @escaping (Result<Void, Error>) -> Void
    ) async throws {
        Task.detached(priority: .userInitiated) {
            let result = await Result(catching: {
                try await self.start()
            })
            
            completion(result)
        }
    }
}
