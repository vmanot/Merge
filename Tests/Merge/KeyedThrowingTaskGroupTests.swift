//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import Testing

@Suite
struct KeyedThrowingTaskGroupTests {
    private actor InvocationCounter {
        private var count = 0

        func increment() -> Int {
            count += 1
            return count
        }

        var value: Int {
            count
        }
    }

    private enum ExpectedError: Error {
        case failure
    }

    @Test
    func testUseExistingPolicy() async throws {
        let graph = KeyedThrowingTaskGroup<TestTasks>()

        try graph.insert(.foo) {
            try await Task.sleep(.milliseconds(200))

            return 1
        }

        let existingResult =  try await graph.perform(.foo, policy: .useExisting) {
            try await Task.sleep(.milliseconds(200))

            return 2
        }

        #expect(existingResult == 1)

        let freshResult = try await graph.perform(.foo, policy: .useExisting) {
            try await Task.sleep(.milliseconds(200))

            return 3
        }

        #expect(freshResult == 3)
    }

    @Test
    func testUnspecifiedInsertionPolicyFailure() async throws {
        let graph = KeyedThrowingTaskGroup<TestTasks>()

        func insertLongFoo() async throws {
            try graph.insert(.foo) {
                try await Task.sleep(.seconds(10))
            }
        }

        try await insertLongFoo()

        var caughtError: Error?

        do {
            try await insertLongFoo()
        } catch {
            caughtError = error
        }

        #expect(caughtError != nil)
    }

    @Test
    func failedTaskDoesNotBecomePermanent() async throws {
        let graph = KeyedThrowingTaskGroup<TestTasks>()

        await #expect(throws: ExpectedError.self) {
            try await graph.perform(.foo, policy: .useExisting) {
                throw ExpectedError.failure
            }
        }

        let result = try await graph.perform(.foo, policy: .useExisting) {
            2
        }
        #expect(result == 2)
    }

    @Test
    func replacedTaskCannotEvictItsReplacement() async throws {
        let graph = KeyedThrowingTaskGroup<TestTasks>()
        let replaced = try graph.insert(.foo) {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                // Deliberately complete after cancellation to exercise stale cleanup.
            }
            return 1
        }
        let replacement = try graph.insert(.foo, policy: .discardPrevious) {
            try await Task.sleep(for: .milliseconds(100))
            return 2
        }

        _ = try await replaced.value
        let reused = try await graph.perform(.foo, policy: .useExisting) {
            3
        }

        #expect(reused == 2)
        #expect(try await replacement.value == 2)
    }

    @Test
    func concurrentUseExistingInsertsCoalesceAtomically() async throws {
        let graph = KeyedThrowingTaskGroup<TestTasks>()
        let invocationCounter = InvocationCounter()

        let results: [Int] = try await withThrowingTaskGroup(
            of: Int.self,
            returning: [Int].self
        ) { group in
            for _ in 0..<20 {
                group.addTask {
                    let task = try graph.insert(.foo, policy: .useExisting) {
                        let invocation = await invocationCounter.increment()
                        try await Task.sleep(for: .milliseconds(50))
                        return invocation
                    }
                    return try await task.value
                }
            }

            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(results.allSatisfy { $0 == 1 })
        #expect(await invocationCounter.value == 1)
    }
}

fileprivate enum TestTasks: Hashable, Sendable {
    case foo
    case bar
    case baz
}
