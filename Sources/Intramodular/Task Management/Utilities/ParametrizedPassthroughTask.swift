//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUIX

/// A task that performs type erasure by wrapping another task.
open class ParametrizedPassthroughTask<Input, Success, Error: Swift.Error>: PassthroughTask<Success, Error>, ParametrizedTask {
    public var input: Input?
    
    required public init(
        body: @escaping (ParametrizedPassthroughTask) -> AnyCancellable
    ) {
        super.init(body: { body($0 as! ParametrizedPassthroughTask) })
    }
    
    convenience public init(
        _ input: Input,
        body: @escaping (ParametrizedPassthroughTask) -> AnyCancellable
    ) {
        self.init(body: body)
        
        self.input = input
    }
    
    public func receive(_ input: Input) {
        self.input = input
    }
}

extension ParametrizedPassthroughTask where Success == Void {
    public class func action(
        _ action: @escaping (ParametrizedPassthroughTask) -> Void
    ) -> Self {
        .action({ action($0 as! ParametrizedPassthroughTask) })
    }
}

extension ParametrizedPassthroughTask {
    public func withInput(_ body: (Input) -> ()) throws {
        if let input = input {
            body(input)
        } else {
            assertionFailure()
        }
    }
}
