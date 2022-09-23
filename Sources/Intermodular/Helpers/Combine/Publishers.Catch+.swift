//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension Publisher {
    /// Discards all errors in the stream.
    public func discardError() -> Publishers.Catch<Self, Publishers.SetFailureType<Combine.Empty<Self.Output, Never>, Never>> {
        self.catch({ _ in Combine.Empty().setFailureType(to: Never.self) })
    }
    
    public func stopExecutionOnError() -> Publishers.Catch<Self, Publishers.SetFailureType<Combine.Empty<Self.Output, Never>, Never>> {
        self.catch { error -> Publishers.SetFailureType<Combine.Empty<Self.Output, Never>, Never> in
            fatalError(error)
        }
    }
    
    public func catchAndMapTo(_ output: Output) -> Publishers.Catch<Self, Just<Self.Output>> {
        self.catch({ _ in Just(output) })
    }
}
