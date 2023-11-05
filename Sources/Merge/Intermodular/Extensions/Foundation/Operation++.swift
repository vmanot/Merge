//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension Foundation.Operation {
    public func addCompletionBlock(_ block: @escaping () -> Void) {
        if let existing = completionBlock {
            completionBlock = {
                existing()
                block()
            }
        } else {
            completionBlock = block
        }
    }
    
    public func addDependencies(_ dependencies: [Foundation.Operation]) {
        for dependency in dependencies {
            addDependency(dependency)
        }
    }
}
