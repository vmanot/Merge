//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import Testing

@Suite
struct ThrowingTaskQueueTests {
    @Test
    func testReentrancy() async throws {
        let queue = TaskQueue()

        queue.addTask {
            _ = await queue.perform {
                0
            }
        }

        _ = await queue.perform {
            assert(queue.isActive)

            _ = await queue.perform {
                0
            }
        }

        await queue.waitForAll()
    }

    @Test
    func testThrowingReentrancy() async throws {
        let queue = ThrowingTaskQueue()

        queue.addTask {
            try await queue.perform {
                0
            }
        }

        _ = try await queue.perform {
            try await queue.perform {
                0
            }
        }

        try await queue.waitForAll()
    }

    @Test
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
