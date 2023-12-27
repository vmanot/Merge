//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import XCTest

final class TaskQueueTests: XCTestCase {
    func testReentrancy() {
        let queue = ThrowingTaskQueue()
        
        queue.addTask {
            try await queue.perform {
               0
            }
        }
    }
    
    func testComplexReentrancy() {
        let queue = ThrowingTaskQueue()
        let queue2 = ThrowingTaskQueue()

        queue.addTask {
            try await queue2.perform {
                try await queue.perform {
                    0
                }
            }
        }
    }
}
