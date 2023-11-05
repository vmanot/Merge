//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension Optional {
    public typealias UnwrapPublisher = Either<Result<Wrapped, Optional<Wrapped>.UnwrappingError>.Publisher, Combine.Fail<Wrapped, UnwrappingError>>
    
    @_disfavoredOverload
    public var unwrapPublisher: UnwrapPublisher {
        guard let wrappedValue = self else {
            return .right(Fail(error: .unexpectedlyFoundNil))
        }
        
        return .left(Just(wrappedValue).setFailureType(to: UnwrappingError.self))
    }
}
