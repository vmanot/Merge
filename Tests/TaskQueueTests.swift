//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import XCTest

final class TaskQueueTests: XCTestCase {
    func testReentrancy() {
        let queue = TaskQueue()
        
        queue.add {
            try await queue.perform {
               0
            }
        }
    }
    
    func testComplexReentrancy() {
        let queue = TaskQueue()
        let queue2 = TaskQueue()

        queue.add {
            try await queue2.perform {
                try await queue.perform {
                    0
                }
            }
        }
    }
}
