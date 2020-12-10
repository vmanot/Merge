//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A type that may be *safely* concurrently referenced from multiple threads.
/// All operations on the conforming type can be assumed to be thread-safe unless explicitly specified otherwise.
public protocol ThreadSafe {
    
}
