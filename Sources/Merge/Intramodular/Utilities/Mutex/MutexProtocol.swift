//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol MutexProtocol: Sendable {
    
}

public protocol ReentrantMutexProtocol: MutexProtocol {
    
}

// MARK: - Deprecated

@available(*, deprecated, renamed: "MutexProtocol")
public typealias Mutex = MutexProtocol
@available(*, deprecated, renamed: "ReentrantMutexProtocol")
public typealias ReentrantMutex = ReentrantMutexProtocol
