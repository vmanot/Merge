//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import Testing

@Suite
struct KeyedThrowingTaskGroupTests {
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
}

fileprivate enum TestTasks: Hashable, Sendable {
    case foo
    case bar
    case baz
}
