//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension Publisher {
    /// Discards all errors in the stream.
    @_transparent
    public func discardError() -> Publishers.Catch<Self, Publishers.SetFailureType<Combine.Empty<Self.Output, Never>, Never>> {
        self.catch({ _ in Combine.Empty().setFailureType(to: Never.self) })
    }
    
    /// Handles errors from an upstream publisher by stopping the execution of the program.
    @_transparent
    public func stopExecutionOnError() -> Publishers.Catch<Self, Publishers.SetFailureType<Combine.Empty<Self.Output, Never>, Never>> {
        self.catch { error -> Publishers.SetFailureType<Combine.Empty<Self.Output, Never>, Never> in
            fatalError(error)
        }
    }
    
    @_transparent
    public func catchAndMapTo(
        _ output: Output
    ) -> Publishers.Catch<Self, Just<Self.Output>> {
        self.catch({ _ in Just(output) })
    }
}
