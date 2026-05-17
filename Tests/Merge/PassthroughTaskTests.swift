//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import Testing

@Suite
struct PassthroughTaskTests {
    @Test
    func testStatus() async throws {
        let task = PassthroughTask<Int, Error>(priority: nil) {
            try await Task.sleep(.seconds(1))

            return 69
        }

        #expect(task.status == .inactive)

        task.start()

        #expect(task.status == .active)

        let value = try await task.value

        #expect(value == 69)
    }
}
