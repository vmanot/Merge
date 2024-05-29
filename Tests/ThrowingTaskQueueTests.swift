//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import XCTest

final class ThrowingTaskQueueTests: XCTestCase {
    func testReentrancy() async throws {
        let queue = ThrowingTaskQueue()
        
        queue.addTask {
            try await queue.perform {
               0
            }
        }
        
        try await queue.waitForAll()
    }
    
    func testComplexReentrancy() async throws {
        let queue = ThrowingTaskQueue()
        let queue2 = ThrowingTaskQueue()

        queue.addTask {
            try await queue2.perform {
                try await queue.perform {
                    0
                }
            }
        }
        
        try await queue.waitForAll()
    }
}
